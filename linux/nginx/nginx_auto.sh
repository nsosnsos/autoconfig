#!/usr/bin/env bash
#set -x
set -e

CUR_USER=$(whoami)
HOME_PATH=$(eval echo ~${CUR_USER})
SCRIPT_PATH=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SCRIPT_NAME=$(basename $(readlink -f "${0}"))
CERT_PATH=${HOME_PATH}/cert
DOMAIN_CONF_FILE=nginx_domain.conf
IP_CONF_FILE=nginx_ip.conf
WEB_NAME=hallelujah

### Check script parameters
if [[ ${#} -eq 2 && ${1} == "install" ]]; then
    if type nginx > /dev/null 2>&1 ; then
        echo "nginx is already installed !!!"
        exit 0
    else
        SITE_NAME=${2}
        if [[ "${SITE_NAME}" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
            SITE_CONF_FILE=${SCRIPT_PATH}/${IP_CONF_FILE}
            DOMAIN_CONFIG=0
        else
            SITE_CONF_FILE=${SCRIPT_PATH}/${DOMAIN_CONF_FILE}
            DOMAIN_CONFIG=1
        fi
        NGINX_PATH=/etc/nginx
        WORK_DIR=workspace
        ACME_DIR=${HOME_PATH}/${WORK_DIR}/${ACME_REPO}
        if [ ! -f ${SITE_CONF_FILE} ]; then
            echo "There is not nginx site conf file !!!"
            exit -1
        fi
    fi
elif [[ ${#} -eq 1 && ${1} == "uninstall" ]]; then
    if type nginx > /dev/null 2>&1 ; then
        echo "uninstalling nginx ..."
        sudo apt purge nginx-* -y
        sudo apt autoremove -y
        bash ${SCRIPT_PATH}/cert_auto.sh uninstall
        sudo rm -rf ${CERT_PATH}
        exit 0
    else
        echo "ngnix is not installed yet !!!"
        exit 0
    fi
else
    echo "Usage: ${SCRIPT_NAME} install/uninstall [SITE_NAME]"
    exit -1
fi

### Automated certificate generation and update
if [[ ! -d ${CERT_PATH} || ! -f ${CERT_PATH}/${SITE_NAME}.key || ! -f ${CERT_PATH}/${SITE_NAME}.cert ]]; then
    echo "Generating certificate ..."
    mkdir -p ${CERT_PATH}
    if [[ ${DOMAIN_CONFIG} -eq 1 ]]; then
        bash ${SCRIPT_PATH}/cert_auto.sh install ${CERT_PATH} ${SITE_NAME}
    else
        openssl req -x509 -newkey rsa:4096 -nodes -out ${CERT_PATH}/${SITE_NAME}.cert -keyout ${CERT_PATH}/${SITE_NAME}.key -days 9999 -subj "/C=US/ST=California/L=SanJose/O=Global Security/OU=IT Department/CN=test@gmail.com"
    fi
fi

### Install nginx
echo "installing nignx ..."
sudo apt install nginx -y

### Config nginx
echo "configuring nginx with site name: [${SITE_NAME}]"
HOST_PATH=${HOME_PATH}/${SITE_NAME}
if [ -f ${NGINX_PATH}/sites-enabled/default ]; then
    sudo rm ${NGINX_PATH}/sites-enabled/default
fi
if [ -f ${NGINX_PATH}/sites-enabled/${SITE_NAME} ]; then
    sudo rm ${NGINX_PATH}/sites-enabled/${SITE_NAME}
fi
sudo cp ${SITE_CONF_FILE} ${NGINX_PATH}/sites-available/${SITE_NAME}
if ! grep -Fq "ssl_certificate" ${NGINX_PATH}/nginx.conf; then
    sudo sed -i "s|ssl_prefer_server_ciphers on;|ssl_prefer_server_ciphers on;\n\tssl_certificate ${CERT_PATH}/${SITE_NAME}.cert;\n\tssl_certificate_key ${CERT_PATH}/${SITE_NAME}.key;|g" ${NGINX_PATH}/nginx.conf
fi
if ! grep -Fq "client_max_body_size" ${NGINX_PATH}/nginx.conf; then
    sudo sed -i "s|sendfile on;|sendfile on;\n\tclient_max_body_size 1024M;|g" ${NGINX_PATH}/nginx.conf
fi
sudo sed -i "s|SITE_NAME|${SITE_NAME}|g" ${NGINX_PATH}/sites-available/${SITE_NAME}
sudo sed -i "s|WEB_NAME|${WEB_NAME}|g" ${NGINX_PATH}/sites-available/${SITE_NAME}
sudo sed -i "s|SITE_PATH|${HOST_PATH}|g" ${NGINX_PATH}/sites-available/${SITE_NAME}
sudo sed -i "s|SITE_CERT|${CERT_PATH}/${SITE_NAME}.cert|g" ${NGINX_PATH}/sites-available/${SITE_NAME}
sudo sed -i "s|SITE_KEY|${CERT_PATH}/${SITE_NAME}.key|g" ${NGINX_PATH}/sites-available/${SITE_NAME}
sudo ln -s ${NGINX_PATH}/sites-available/${SITE_NAME} ${NGINX_PATH}/sites-enabled/${SITE_NAME}
sudo systemctl restart nginx

