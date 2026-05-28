
PREFIX = /usr/local/bin
SYSTEM_DIR = /etc/systemd/system

all: install

.PHONY: install
install:
	@echo "Installing ..."

	@install -m 0755 coolify-auto-deploy.bash $(PREFIX)/coolify-auto-deploy

	@install -m 0644 src/system/coolify-auto-deploy.service $(SYSTEM_DIR)/
	@install -m 0644 src/system/coolify-auto-deploy.timer $(SYSTEM_DIR)/

	@systemctl daemon-reload
	@systemctl enable coolify-auto-deploy.timer

	@echo "Installation complete!"

.PHONY: uninstall
uninstall:
	@echo "Uninstalling ..."

	@systemctl disable --now coolify-auto-deploy.timer 2>/dev/null || true
	@systemctl daemon-reload

	@rm -f $(PREFIX)/coolify-auto-deploy
	@rm -f $(SYSTEM_DIR)/coolify-auto-deploy.service
	@rm -f $(SYSTEM_DIR)/coolify-auto-deploy.timer

	@echo "Uninstallation complete!"

.PHONY: help
help:
	@echo "Usage:"
	@echo "  make install    - Install"
	@echo "  make uninstall  - Remove"
	@echo "  make help       - Show this help"
