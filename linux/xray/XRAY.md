# Unified VPS services

Install with a domain name or IPv4 address; the existing host detection and certificate selection are retained.

```bash
sudo bash linux/auto_init.sh install example.com
sudo bash linux/auto_init.sh install 203.0.113.10
sudo bash linux/auto_init.sh uninstall
```

## Ports

| Service | Internal listener | Nginx / public access |
|---|---|---|
| Website backend | TCP 6600 | Nginx HTTPS site -> 127.0.0.1:6600 |
| Shellinabox backend | TCP 7700 | Nginx HTTPS /sh -> 127.0.0.1:7700 |
| Notebook | TCP 8800 on 127.0.0.1 | Nginx HTTPS /nb -> 127.0.0.1:8800 |
| VMess WebSocket | TCP 9900 on 127.0.0.1 | Nginx HTTPS WebSocket /ws -> 127.0.0.1:9900 |
| VLESS + REALITY + Vision | TCP 9990 | Xray directly listens on 0.0.0.0:9990 |
| Hysteria2 | UDP 9999 | Xray directly listens on 0.0.0.0:9999 |

Notebook and VMess ports are internal backend ports only. Nginx terminates TLS on the existing HTTPS site (TCP/443) and proxies /nb and /ws to their loopback listeners. TCP/8800 and TCP/9900 must not be opened in the firewall. Nginx handles HTTP/HTTPS only; no Nginx stream module or stream configuration is added.

## Directory layout

Xray is maintained independently from V2Ray:
- V2Ray installer and configuration: linux/v2ray/
- Xray installer and configuration: linux/xray/

## Certificate selection

- An IPv4 address creates a self-signed certificate with IP SAN.
- A domain name uses Certbot to obtain a publicly trusted certificate. DNS must point to this VPS and TCP/80 must be reachable.
- Self-signed IP certificates must be trusted/imported by clients that validate TLS.

## Firewall

Allow TCP 80, 443, 9990 and UDP 9999. Do not expose backend ports 6600, 7700, 8800 or 9900 directly.
