# Profiles

## cloud-web
- Opens: SSH + 80 + 443 (via UFW)
- SSH forwarding disabled (safer for web servers)

Security Group (recommended):
- Allow 22 from your IP/VPN only
- Allow 80/443 from anywhere (or your CDN/LB)

## bastion
- Opens: SSH only (via UFW)
- Enables TCP forwarding for ProxyJump/port forwarding
- Agent forwarding disabled by default (risk tradeoff)

Security Group (recommended):
- Allow 22 ONLY from your IP/VPN (tight allowlist)
- No 80/443
