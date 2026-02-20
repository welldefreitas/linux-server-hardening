SHELL := /bin/bash

.PHONY: help deps audit dry-run apply backup rollback fmt lint

help:
	@echo "Targets:"
	@echo "  make deps      - Install required packages"
	@echo "  make audit     - Audit current system state (no changes)"
	@echo "  make dry-run   - Show what would change (no changes)"
	@echo "  make apply     - Apply hardening baseline (with backups)"
	@echo "  make backup    - Backup relevant config files"
	@echo "  make rollback  - Restore from last backup"
	@echo "  make lint      - Run local lint checks (ShellCheck/shfmt if installed)"

deps:
	sudo bash scripts/install-deps.sh

audit:
	sudo bash scripts/audit.sh

dry-run:
	sudo DRY_RUN=1 bash scripts/apply.sh

apply:
	sudo bash scripts/apply.sh

backup:
	sudo bash scripts/backup.sh

rollback:
	sudo bash scripts/rollback.sh

lint:
	@command -v shellcheck >/dev/null && shellcheck scripts/*.sh || true
	@command -v shfmt >/dev/null && shfmt -d -i 2 -ci scripts/*.sh || true
