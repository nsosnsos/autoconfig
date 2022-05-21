#!/bin/bash
set -e
set -x

HOME_DIR=$(eval echo ~${SUDO_USER})
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

### Check for site certificate
if [[ ! -f ${SCRIPT_DIR}/site.cert || ! -f ${SCRIPT_DIR}/site.key ]]; then
    echo "Get site certificate first !!!"
    exit -1
fi

### Config nginx
read -p "Enter SITE_NAME: " SITE_NAME
if [ -z "${SITE_NAME}" ]; then
    echo "Error: Empty SITE_NAME !!!"
    exit -1
fi
echo "Configuring nginx with site name: [${SITE_NAME}]"
NGINX_CONFIG_PATH=/etc/nginx
HOST_PATH=${HOME_DIR}/${SITE_NAME}
mkdir -p ${HOST_PATH}/cert
if [ -f ${NGINX_CONFIG_PATH}/sites-enabled/default ]; then
    rm ${NGINX_CONFIG_PATH}/sites-enabled/default
fi
if [ -f ${NGINX_CONFIG_PATH}/sites-enabled/${SITE_NAME} ]; then
    rm ${NGINX_CONFIG_PATH}/sites-enabled/${SITE_NAME}
fi
sudo cp site.conf ${NGINX_CONFIG_PATH}/sites-available/${SITE_NAME}
sudo cp site.cert ${HOST_PATH}/cert/${SITE_NAME}.cert
sudo cp site.key ${HOST_PATH}/cert/${SITE_NAME}.key
sudo sed -z "s|ssl_prefer_server_ciphers on;\n\n|ssl_prefer_server_ciphers on;\n\tssl_certificate ${HOST_PATH}/cert/${SITE_NAME}.cert;\n\tssl_certificate_key ${HOST_PATH}/cert/${SITE_NAME}.key;\n\n|g" /etc/nginx/nginx.conf | sudo tee /etc/nginx/nginx.conf > /dev/null
sudo sed -i 's|SITE_NAME|'${SITE_NAME}'|g' ${NGINX_CONFIG_PATH}/sites-available/${SITE_NAME}
sudo sed -i 's|SITE_PATH|'${HOST_PATH}'|g' ${NGINX_CONFIG_PATH}/sites-available/${SITE_NAME}
sudo sed -i 's|SITE_CERT|'${HOST_PATH}/cert/${SITE_NAME}.cert'|g' ${NGINX_CONFIG_PATH}/sites-available/${SITE_NAME}
sudo sed -i 's|SITE_KEY|'${HOST_PATH}/cert/${SITE_NAME}.key'|g' ${NGINX_CONFIG_PATH}/sites-available/${SITE_NAME}
sudo ln -s ${NGINX_CONFIG_PATH}/sites-available/${SITE_NAME} ${NGINX_CONFIG_PATH}/sites-enabled/${SITE_NAME}
sudo chown -R www-data:www-data ${HOST_PATH}
sudo service nginx restart

