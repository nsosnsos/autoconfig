#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="${SCRIPT_DIR}/xray_config.json"
CONFIG=/usr/local/etc/xray/config.json
XRAY=/usr/local/bin/xray
INSTALLER=https://github.com/XTLS/Xray-install/raw/main/install-release.sh
usage() { echo "Usage: xray_auto.sh install SITE_NAME_OR_IP | uninstall"; exit 2; }
if [[ $EUID -ne 0 ]]; then exec sudo -E bash "$0" "$@"; fi
if [[ ${1:-} == uninstall && $# -eq 1 ]]; then
  systemctl disable --now xray >/dev/null 2>&1 || true
  if [[ -x "$XRAY" ]]; then bash -c "$(curl -fsSL "$INSTALLER")" @ remove; fi
  exit 0
fi
[[ $# -eq 2 && $1 == install ]] || usage
HOST="$2"
RUN_USER="${SUDO_USER:-root}"
RUN_HOME="$(getent passwd "$RUN_USER" | cut -d: -f6)"
CERT_FILE="$RUN_HOME/cert/$HOST.fullchain.pem"
KEY_FILE="$RUN_HOME/cert/$HOST.privkey.pem"
[[ -s "$CERT_FILE" && -s "$KEY_FILE" ]] || { echo "Missing TLS cert/key for Hysteria2: $CERT_FILE $KEY_FILE" >&2; exit 1; }
command -v curl >/dev/null; command -v openssl >/dev/null; command -v python3 >/dev/null
if [[ ! -x "$XRAY" ]]; then
  tmp="$(mktemp)"; trap 'rm -f "$tmp"' EXIT
  curl -fsSL "$INSTALLER" -o "$tmp"; bash "$tmp" install
fi
UUID="$("$XRAY" uuid)"
KEYS="$("$XRAY" x25519)"
PRIVATE="$(awk -F': *' '/^PrivateKey:/ {print $2; exit}' <<<"$KEYS")"
PUBLIC="$(awk -F': *' '/^(Password|PublicKey):/ {print $2; exit}' <<<"$KEYS")"
SHORT_ID="$(openssl rand -hex 8)"
HY2_PASSWORD="$(openssl rand -hex 24)"
[[ -n "$PRIVATE" && -n "$PUBLIC" ]] || { echo "Xray x25519 key generation failed." >&2; exit 1; }
install -d -m 0755 /usr/local/etc/xray /var/log/xray
export UUID PRIVATE SHORT_ID HY2_PASSWORD CERT_FILE KEY_FILE
python3 - "$TEMPLATE" "$CONFIG" <<'PY'
import json, os, sys
with open(sys.argv[1], encoding="utf-8") as f: cfg=json.load(f)
r={"__UUID__":os.environ["UUID"],"__REALITY_PRIVATE_KEY__":os.environ["PRIVATE"],"__REALITY_SHORT_ID__":os.environ["SHORT_ID"],"__HY2_PASSWORD__":os.environ["HY2_PASSWORD"],"__CERT_FILE__":os.environ["CERT_FILE"],"__KEY_FILE__":os.environ["KEY_FILE"]}
def sub(v):
    if isinstance(v,dict): return {k:sub(x) for k,x in v.items()}
    if isinstance(v,list): return [sub(x) for x in v]
    if isinstance(v,str):
        for k,val in r.items(): v=v.replace(k,val)
    return v
cfg=sub(cfg)
with open(sys.argv[2],"w",encoding="utf-8") as f: json.dump(cfg,f,indent=2); f.write("\n")
PY
chmod 0600 "$CONFIG"
"$XRAY" run -test -config "$CONFIG"
systemctl enable xray
systemctl restart xray
cat <<EOF
VLESS + REALITY + Vision
  Address: $HOST
  Port: TCP/9990
  UUID: $UUID
  SNI: www.microsoft.com
  Public key: $PUBLIC
  Short ID: $SHORT_ID
  Link: vless://$UUID@$HOST:9990?encryption=none&flow=xtls-rprx-vision&security=reality&sni=www.microsoft.com&fp=chrome&pbk=$PUBLIC&sid=$SHORT_ID&type=tcp#VLESS-Reality

Hysteria2
  Address: $HOST
  Port: UDP/9999
  Password: $HY2_PASSWORD
  Link: hysteria2://$HY2_PASSWORD@$HOST:9999/?sni=$HOST&alpn=h3#Hysteria2
EOF
