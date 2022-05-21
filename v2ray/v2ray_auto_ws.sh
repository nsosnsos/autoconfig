#!/usr/bin/env bash
set -e
set -x

HOME_DIR=$(eval echo ~${SUDO_USER})
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

NGINX_CONFIG_PATH=/etc/nginx
SITE_NAME=v2ray
HOST_PATH=${HOME_DIR}/${SITE_NAME}

### Check for site certificate
CERT_DIR=${SCRIPT_DIR}/../oracle_cloud
if [[ ! -f ${CERT_DIR}/site.cert || ! -f ${CERT_DIR}/site.key ]]; then
    echo "Get site certificate first !!!"
    exit -1
fi
if [ -f ${NGINX_CONFIG_PATH}/sites-enabled/${SITE_NAME} ]; then
    sudo rm ${NGINX_CONFIG_PATH}/sites-enabled/${SITE_NAME}
fi

mkdir -p ${HOST_PATH}/cert
sudo cp nginx_ws.conf ${NGINX_CONFIG_PATH}/sites-available/${SITE_NAME}
sudo cp ${CERT_DIR}/site.cert ${HOST_PATH}/cert/${SITE_NAME}.cert
sudo cp ${CERT_DIR}/site.key ${HOST_PATH}/cert/${SITE_NAME}.key
sudo sed -i 's|SITE_NAME|'${SITE_NAME}'|g' ${NGINX_CONFIG_PATH}/sites-available/${SITE_NAME}
sudo sed -i 's|SITE_PATH|'${HOST_PATH}'|g' ${NGINX_CONFIG_PATH}/sites-available/${SITE_NAME}
sudo sed -i 's|SITE_CERT|'${HOST_PATH}/cert/${SITE_NAME}.cert'|g' ${NGINX_CONFIG_PATH}/sites-available/${SITE_NAME}
sudo sed -i 's|SITE_KEY|'${HOST_PATH}/cert/${SITE_NAME}.key'|g' ${NGINX_CONFIG_PATH}/sites-available/${SITE_NAME}
sudo ln -s ${NGINX_CONFIG_PATH}/sites-available/${SITE_NAME} ${NGINX_CONFIG_PATH}/sites-enabled/${SITE_NAME}

sudo cp v2ray_config_ws.json /usr/local/etc/v2ray/config.json
sudo systemctl restart v2ray
sudo systemctl restart nginx

