# Rollback

## What rollback restores
- sshd config + drop-in file
- sysctl baseline file
- auditd rules file
- fail2ban jail file
- ufw rules

## How to rollback
```bash
sudo make rollback
