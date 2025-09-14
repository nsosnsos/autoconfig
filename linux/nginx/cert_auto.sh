#!/usr/bin/env bash
#set -x
set -e

CUR_USER=$(whoami)
HOME_PATH=$(eval echo ~${CUR_USER})
SCRIPT_PATH=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SCRIPT_NAME=$(basename $(readlink -f "${0}"))
CERT_SVC=certbot

function cron_add () {
    read -p "input cert path: " CERT_PATH
    read -p "input site name: " SITE_NAME
    CRON_JOB="0 2 1 * * ${SCRIPT_PATH}/${SCRIPT_NAME} cron ${CERT_PATH} ${SITE_NAME}"

    if crontab -l 2>/dev/null | grep -Fq "${CRON_JOB}"; then
        crontab -l | grep -Fv "${CRON_JOB}" | crontab -
    fi

    if [[ -z "$(crontab -l)" ]]; then
        echo "${CRON_JOB}" | crontab -
    else
        (echo "$(crontab -l)"; echo "${CRON_JOB}") | crontab -
    fi
}

function cron_job () {
    CERT_PATH=${1}
    SITE_NAME=${2}
    if [ -f ${CERT_PATH}/${SITE_NAME}.cert ]; then
        mv -f ${CERT_PATH}/${SITE_NAME}.cert ${CERT_PATH}/${SITE_NAME}.cert.bak
    fi
    if [ -f ${CERT_PATH}/${SITE_NAME}.key ]; then
        mv -f ${CERT_PATH}/${SITE_NAME}.key ${CERT_PATH}/${SITE_NAME}.key.bak
    fi
    sudo rm -rf /etc/letsencrypt
    ${SCRIPT_PATH}/${SCRIPT_NAME} install ${CERT_PATH} ${SITE_NAME}
}


### Check script parameters
if [[ ${#} == 2 && ${1} == "uninstall" ]]; then
    sudo rm -rf /etc/letsencrypt
    sudo apt purge certbot -y
    sudo apt autoremove -y
    CERT_PATH=${2}
    rm -rf ${CERT_PATH}
    exit 0
elif [[ ${#} -eq 3 && ${1} == "install" ]]; then
    CERT_PATH=${2}
    SITE_NAME=${3}
elif [[ ${#} -ge 1 && ${1} == "cron" ]]; then
    if [[ ${#} -ne 3 ]]; then
        cron_add
    else
        cron_job ${2} ${3}
    fi
    exit 0
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
    sudo chown ${CUR_USER}:${CUR_USER} ${CERT_PATH}/${SITE_NAME}.cert
    sudo chown ${CUR_USER}:${CUR_USER} ${CERT_PATH}/${SITE_NAME}.key
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

