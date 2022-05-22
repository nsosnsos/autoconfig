#!/usr/bin/env bash
set -e
set -x

HOME_DIR=$(eval echo ~${SUDO_USER})
SCRIPT_PATH=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

SITE_NAME=v2ray
SITE_CERT_PATH=${SCRIPT_PATH}/../oracle_cloud
SITE_CONF_FILE=${SCRIPT_PATH}/nginx_ws.conf

sudo bash ${SITE_CERT_PATH}/nginx_init.sh ${SITE_CERT_PATH} ${SITE_CONF_FILE}
sudo cp ${SCRIPT_PATH}/v2ray_config_ws.json /usr/local/etc/v2ray/config.json

sudo systemctl restart v2ray
sudo systemctl restart nginx

