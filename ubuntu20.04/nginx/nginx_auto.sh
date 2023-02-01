#!/usr/bin/env bash
#set -x
set -e

HOME_PATH=$(eval echo ~${SUDO_USER})
CERT_PATH=${HOME_PATH}/cert
SCRIPT_PATH=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SCRIPT_NAME=$(basename $(readlink -f "${0}"))

### Check script parameters
if [[ ${#} != 1 ]]; then
    echo "Usage: ${SCRIPT_NAME}: SITE_NAME"
    exit -1
elif type nginx > /dev/null 2>&1 ; then
    echo "nginx is already installed !!!"
    exit 0
else
    SITE_NAME=${1}
    SITE_CERT_PATH=${CERT_PATH}
    SITE_CONF_FILE=${SCRIPT_PATH}/nginx.conf
    if [ ! -f ${SITE_CONF_FILE} ]; then
        echo "There is not nginx site conf file !!!"
        exit -1
    fi
fi

### Self-signed cetificate generation
if [[ ! -d ${CERT_PATH} || ! -f ${CERT_PATH}/site.key || ! -f ${CERT_PATH}/site.cert ]]; then
    echo "Generating self signed certificate ..."
    mkdir -p ${CERT_PATH}
    openssl req -x509 -newkey rsa:4096 -nodes -out ${CERT_PATH}/site.cert -keyout ${CERT_PATH}/site.key -days 9999 -subj "/C=US/ST=California/L=SanJose/O=Global Security/OU=IT Department/CN=test@gmail.com"
fi

### Check nginx installation
NGINX_PATH=/etc/nginx
if [[ ! -f ${NGINX_PATH}/nginx.conf ]]; then
    sudo apt install -y nginx
fi

### Config nginx
echo "Configuring nginx with site name: [${SITE_NAME}]"
HOST_PATH=${HOME_PATH}/${SITE_NAME}
sudo mkdir -p ${HOST_PATH}/cert
if [ -f ${NGINX_PATH}/sites-enabled/default ]; then
    sudo rm ${NGINX_PATH}/sites-enabled/default
fi
if [ -f ${NGINX_PATH}/sites-enabled/${SITE_NAME} ]; then
    sudo rm ${NGINX_PATH}/sites-enabled/${SITE_NAME}
fi
sudo cp ${SITE_CONF_FILE} ${NGINX_PATH}/sites-available/${SITE_NAME}
sudo cp ${SITE_CERT_PATH}/site.cert ${HOST_PATH}/cert/${SITE_NAME}.cert
sudo cp ${SITE_CERT_PATH}/site.key ${HOST_PATH}/cert/${SITE_NAME}.key
if ! grep -Fq "ssl_certificate" ${NGINX_PATH}/nginx.conf; then
    sudo sed -i "s|ssl_prefer_server_ciphers on;|ssl_prefer_server_ciphers on;\n\tssl_certificate ${HOST_PATH}/cert/${SITE_NAME}.cert;\n\tssl_certificate_key ${HOST_PATH}/cert/${SITE_NAME}.key;|g" ${NGINX_PATH}/nginx.conf
fi
if ! grep -Fq "client_max_body_size" ${NGINX_PATH}/nginx.conf; then
    sudo sed -i "s|sendfile on;|sendfile on;\n\tclient_max_body_size 1024M;|g" ${NGINX_PATH}/nginx.conf
fi
sudo sed -i 's|SITE_NAME|'${SITE_NAME}'|g' ${NGINX_PATH}/sites-available/${SITE_NAME}
sudo sed -i 's|SITE_PATH|'${HOST_PATH}'|g' ${NGINX_PATH}/sites-available/${SITE_NAME}
sudo sed -i 's|SITE_CERT|'${HOST_PATH}/cert/${SITE_NAME}.cert'|g' ${NGINX_PATH}/sites-available/${SITE_NAME}
sudo sed -i 's|SITE_KEY|'${HOST_PATH}/cert/${SITE_NAME}.key'|g' ${NGINX_PATH}/sites-available/${SITE_NAME}
sudo ln -s ${NGINX_PATH}/sites-available/${SITE_NAME} ${NGINX_PATH}/sites-enabled/${SITE_NAME}
sudo chown -R www-data:www-data ${HOST_PATH}
sudo systemctl restart nginx

