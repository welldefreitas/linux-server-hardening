SHELL := /bin/bash

.PHONY: help deps audit dry-run apply backup rollback lint \
        apply-cloud-web apply-bastion dry-run-cloud-web dry-run-bastion

help:
	@echo "Targets:"
	@echo "  make deps              - Install required packages (Ubuntu/Debian)"
	@echo "  make audit             - Audit current system state (no changes)"
	@echo "  make dry-run           - Show what would change (no changes)"
	@echo "  make apply             - Apply hardening baseline (with backups)"
	@echo "  make backup            - Backup relevant config files"
	@echo "  make rollback          - Restore from last backup"
	@echo "  make lint              - Run local lint checks (ShellCheck/shfmt if installed)"
	@echo ""
	@echo "Profiles:"
	@echo "  make dry-run-cloud-web - DRY_RUN apply with PROFILE=cloud-web"
	@echo "  make apply-cloud-web   - Apply with PROFILE=cloud-web (SSH + 80/443)"
	@echo "  make dry-run-bastion   - DRY_RUN apply with PROFILE=bastion"
	@echo "  make apply-bastion     - Apply with PROFILE=bastion (SSH only, forwarding enabled)"

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

apply-cloud-web:
	sudo PROFILE=cloud-web bash scripts/apply.sh

apply-bastion:
	sudo PROFILE=bastion bash scripts/apply.sh

dry-run-cloud-web:
	sudo PROFILE=cloud-web DRY_RUN=1 bash scripts/apply.sh

dry-run-bastion:
	sudo PROFILE=bastion DRY_RUN=1 bash scripts/apply.sh

lint:
	@command -v shellcheck >/dev/null && shellcheck scripts/*.sh || true
	@command -v shfmt >/dev/null && shfmt -d -i 2 -ci scripts/*.sh || true
