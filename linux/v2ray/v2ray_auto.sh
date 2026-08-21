#!/usr/bin/env bash
#set -x
set -e

CUR_USER=$(whoami)
HOME_PATH=$(eval echo ~${CUR_USER})
SCRIPT_PATH=$(dirname $(readlink -f "${BASH_SOURCE[0]}"))
SCRIPT_NAME=$(basename $(readlink -f "${BASH_SOURCE[0]}"))
source ${SCRIPT_PATH}/../logging.sh
WORK_DIR=workspace
V2RAY_REPO=fhs-install-v2ray
V2RAY_DIR=${HOME_PATH}/${WORK_DIR}/${V2RAY_REPO}
V2RAY_CONF=v2ray_config.json

if [[ ${#} -eq 2 && ${1} == "install" ]]; then
    if type v2ray > /dev/null 2>&1 ; then
        log_info "v2ray is already installed"
        exit 0
    else
        SITE_NAME=${2}
        if [[ "${SITE_NAME}" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
            CONF_FILE=${SCRIPT_PATH}/${V2RAY_CONF}
        else
            CONF_FILE=${SCRIPT_PATH}/${V2RAY_CONF}
        fi
        if [ ! -f ${CONF_FILE} ]; then
            log_error "There is no v2ray config file [${CONF_FILE}]"
            exit 1
        fi
        GITHUB_USER=$(git config user.name)
    fi
elif [[ ${#} -eq 1 && ${1} == "uninstall" ]]; then
    if type v2ray > /dev/null 2>&1 ; then
        log_info "uninstalling v2ray ..."
        sudo bash ${V2RAY_DIR}/install-release.sh --remove
        log_exec "sudo rm -rf /usr/local/etc/v2ray /var/log/v2ray"
        exit 0
    else
        log_info "v2ray is not installed yet"
        exit 0
    fi
else
    log_error "Usage: ${SCRIPT_NAME} install/uninstall [SITE_NAME]"
    log_error "       You should have repo at git@github.com:[GITHUB_USER]/${V2RAY_REPO}.git first"
    log_error "       Or you need fork it at https://github.com/v2fly/fhs-install-v2ray"
    exit 1
fi

### Install v2ray
log_info "installing v2ray..."
if [ ! -d ${V2RAY_DIR} ]; then
    log_info "Downloading ${V2RAY_REPO} repository, you should have forked ${V2RAY_REPO}!"
    mkdir -p ${HOME_PATH}/${WORK_DIR}
    cd ${HOME_PATH}/${WORK_DIR}
    log_exec "git clone git@github.com:${GITHUB_USER}/${V2RAY_REPO}.git"
    cd -
fi

log_exec "sudo bash ${V2RAY_DIR}/install-release.sh"
log_exec "sudo bash ${V2RAY_DIR}/install-dat-release.sh"

### Config v2ray
log_info "configuring v2ray..."
log_exec "sudo cp ${CONF_FILE} /usr/local/etc/v2ray/config.json"
log_info "Default v2ray id: 00000000-0000-0000-0000-000000000000"
log_info "Please modify to v2ray config id by [uuidgen]"
read -p "Enter v2ray id: " V2RAY_ID
sudo sed -i "s|00000000-0000-0000-0000-000000000000|${V2RAY_ID}|g" /usr/local/etc/v2ray/config.json
sudo sed -i "s|SITE_NAME|${SITE_NAME}|g" /usr/local/etc/v2ray/config.json
log_exec "sudo systemctl enable v2ray"
log_exec "sudo systemctl restart v2ray"
log_info "v2ray installation completed successfully"

