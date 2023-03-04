#!/usr/bin/env bash
#set -x
set -e

CUR_USER=$(whoami)
HOME_PATH=$(eval echo ~${CUR_USER})
CERT_PATH=${HOME_PATH}/cert
SCRIPT_PATH=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SCRIPT_NAME=$(basename $(readlink -f "${0}"))
WORK_DIR=workspace
ACME_REPO=acme.sh

### Check script parameters
if [[ ${#} -ne 1 ]]; then
    echo "Usage:     ${SCRIPT_NAME} SITE_NAME"
    echo "Attention: You should have configured SITE_NAME correctly for nginx, and WWW-ROOT works well."
    exit -1
else
    SITE_NAME=${1}
    GITHUB_USER=$(git config user.name)
    ACME_DIR=${HOME_PATH}/${WORK_DIR}/${ACME_REPO}
fi

### Automated certificate generation and update
if [ ! -d ${ACME_DIR} ]; then
    echo "Downloading ${ACME_REPO} repository, you should have forked ${ACME_REPO}!"
    mkdir -p ${HOME_PATH}/${WORK_DIR}
    cd ${HOME_PATH}/${WORK_DIR}
    git clone git@github.com:${GITHUB_USER}/${ACME_REPO}.git
    cd -
fi

cd ${ACME_DIR}
sudo ${ACME_DIR}/${ACME_REPO} --install -m ${SITE_NAME}@${SITE_NAME}
${ACME_DIR}/${ACME_REPO} --issue -d ${SITE_NAME} --nginx
${ACME_DIR}/${ACME_REPO} --install-cert -d ${SITE_NAME} --key-file ${CERT_PATH}/${SITE_NAME}.key --fullchain-file ${CERT_PATH}/${SITE_NAME}.cert --reloadcmd "service nginx force-reload"
cd -

### Self-signed cetificate generation
#if [[ ! -d ${CERT_PATH} || ! -f ${CERT_PATH}/${SITE_NAME}.key || ! -f ${CERT_PATH}/${SITE_NAME}.cert ]]; then
#    echo "Generating self signed certificate ..."
#    mkdir -p ${CERT_PATH}
#    openssl req -x509 -newkey rsa:4096 -nodes -out ${CERT_PATH}/${SITE_NAME}.cert -keyout ${CERT_PATH}/${SITE_NAME}.key -days 9999 -subj "/C=US/ST=California/L=SanJose/O=Global Security/OU=IT Department/CN=test@gmail.com"
#fi

