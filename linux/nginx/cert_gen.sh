#!/usr/bin/env bash
#set -x
set -e

CUR_USER=$(whoami)
HOME_PATH=$(eval echo ~${CUR_USER})
SCRIPT_PATH=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SCRIPT_NAME=$(basename $(readlink -f "${0}"))
WORK_DIR=workspace
CERT_SVC=certbot

### Check script parameters
if [[ ${#} == 1 && ${1} == "uninstall" ]]; then
    sudo apt purge certbot -y
    sudo apt autoremove -y
    exit 0
elif [[ ${#} -eq 3 && ${1} == "install" ]]; then
    CERT_PATH=${2}
    SITE_NAME=${3}
else
    echo "Usage:     ${SCRIPT_NAME} install/uninstall CERT_PATH SITE_NAME"
    echo "Attention: certificate generation succeed only if nginx is not installed or not running."
    exit -1
fi

if [[ -f ${CERT_PATH}/${SITE_NAME}.cert ]]; then
    echo "You have already have the certificate, no need to generate again."
    exit 0
else
    sudo apt install ${CERT_SVC} -y
    if type nginx > /dev/null 2>&1 ; then
        sudo service nginx stop
    fi
    sudo ${CERT_SVC} certonly --standalone --non-interactive --agree-tos --email test@test.com -d ${SITE_NAME} -d www.${SITE_NAME}
    if [[ ! -d ${CERT_PATH} ]]; then
        mkdir -p ${CERT_PATH}
    fi
    sudo cp /etc/letsencrypt/live/${SITE_NAME}/fullchain.pem ${CERT_PATH}/${SITE_NAME}.cert
    sudo cp /etc/letsencrypt/live/${SITE_NAME}/privkey.pem ${CERT_PATH}/${SITE_NAME}.key
    if type nginx > /dev/null 2>&1 ; then
        sudo service nginx restart
    fi
fi

### Self-signed certificate generation
#if [[ ! -d ${CERT_PATH} || ! -f ${CERT_PATH}/${SITE_NAME}.key || ! -f ${CERT_PATH}/${SITE_NAME}.cert ]]; then
#    echo "Generating self signed certificate ..."
#    mkdir -p ${CERT_PATH}
#    openssl req -x509 -newkey rsa:4096 -nodes -out ${CERT_PATH}/${SITE_NAME}.cert -keyout ${CERT_PATH}/${SITE_NAME}.key -days 9999 -subj "/C=US/ST=California/L=SanJose/O=Global Security/OU=IT Department/CN=test@gmail.com"
#fi

