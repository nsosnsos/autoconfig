#!/usr/bin/env bash
set -e
set -x

HOME_DIR=$(eval echo ~${SUDO_USER})
SCRIPT_PATH=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SCRIPT_NAME=$(basename $(readlink -f "${0}"))

SITE_NAME=v2ray
if [ ${#} != 2 ]; then
    echo "Wrong parameters !!"
    echo "Usage ${SCRIPT_NAME} SITE_CERT_PATH SITE_CONF_PATH"
    exit -1
fi

bash ${SCRIPT_PATH}/../oracle_cloud/nginx_init.sh ${1} ${2} ${SITE_NAME}
sudo cp ${SCRIPT_PATH}/v2ray_config_ws.json /usr/local/etc/v2ray/config.json

sudo systemctl restart v2ray
sudo systemctl restart nginx

