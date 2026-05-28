#!/bin/bash
LOG_FILE="/var/log/coolify-auto-deploy.log"
LOG_FILE_DEBUG="./coolify-auto-deploy.log"

log() {
    local LEVEL_NAME="UNKNOWN"
    local LOG_LEVEL="${2:-1}"

    case $LOG_LEVEL in
        0) LEVEL_NAME="DEBUG";;
        1) LEVEL_NAME="INFO";;
        2) LEVEL_NAME="WARNING";;
        3) LEVEL_NAME="ERROR";;
        *) LEVEL_NAME="UNKNOWN";; # Fallback for unexpected levels
    esac

    if (( LOG_LEVEL >= LOG_LEVEL_THRESHOLD || LOG_LEVEL == -1 )); then
        local OUTPUT="$(date '+%Y-%m-%d %H:%M:%S') [$LEVEL_NAME] - $1"

        if [[ -e "$LOG_FILE" ]] || touch "$LOG_FILE" 2>/dev/null; then
            echo "$OUTPUT" >>"$LOG_FILE"
        else
            echo "$OUTPUT" >>"$LOG_FILE_DEBUG"
        fi
    fi
}

restart_service() {
    log "Attempting to restart Coolify service '$SERVICE_ID'..." 1

    local TEMP_RESPONSE_FILE=$(mktemp)
    local API_URL="${COOLIFY_BASE_URL}/api/v1/deploy?uuid=${SERVICE_ID}&force=true"

    if coolify_api_request "$API_URL" "POST"; then
        log "Successfully sent restart command for service '$SERVICE_ID'."
        return 0
    else
        log "Failed to restart service '$SERVICE_ID'." 2
        return 1
    fi
}

coolify_api_request() {
    local TEMP_RESPONSE_FILE=$(mktemp)
    local API_URL=$1
    local API_METHOD="${2:-GET}"

    log "API Request: Method=$API_METHOD, URL=$API_URL" 0

    local HTTP_STATUS=$(curl -s -o "$TEMP_RESPONSE_FILE" -w "%{http_code}" \
                        -X "$API_METHOD" \
                        -H "Authorization: Bearer ${COOLIFY_API_TOKEN}" \
                        "${API_URL}")

    local RESPONSE_BODY=$(cat "$TEMP_RESPONSE_FILE")
    rm "$TEMP_RESPONSE_FILE"

    if [[ "$HTTP_STATUS" -ge 200 && "$HTTP_STATUS" -lt 300 ]]; then
        log "Request Failed. HTTP Status: $HTTP_STATUS. API Response Body: $RESPONSE_BODY" 2
        return 0
    else
        log "Request Failed. HTTP Status: $HTTP_STATUS. API Response Body: $RESPONSE_BODY" 2
        return 1
    fi
}

health_check() {

    local HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "${HEALTH_URL}")

    if [[ "$HTTP_STATUS" -ge 200 ]]; then
        return 0
    else
        return 1
    fi
}

if [ -f "./coolify-auto-deploy.conf" ]; then
    source "./coolify-auto-deploy.conf"
elif [ -f "/etc/coolify-auto-deploy.conf" ]; then
    source "/etc/coolify-auto-deploy.conf"
else
    log "Configuration file not found!" 3
    exit 1
fi

if health_check ; then
    log "'$SERVICE_ID' is healthy ..." 1
else
    log "'$SERVICE_ID' is unhealthy ..." 1
    restart_service
fi