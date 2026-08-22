#!/usr/bin/env bash
#set -x
set -e

CUR_USER=${SUDO_USER:-$(whoami)}
HOME_PATH=$(eval echo "~${CUR_USER}")
SCRIPT_PATH=$(dirname $(readlink -f "${BASH_SOURCE[0]}"))
SCRIPT_NAME=$(basename $(readlink -f "${BASH_SOURCE[0]}"))
source ${SCRIPT_PATH}/logging.sh


function help () {
    log_error "Usage: ${SCRIPT_NAME} [install|uninstall] [SITE_NAME]"
    log_error "Attention: SITE_NAME is used for nginx server name."
    log_error "           It could be a domain name or an ip address."
    exit 1
}

function auto_uninstall () {
    log_info "Starting uninstallation process..."
    bash ${SCRIPT_PATH}/redis/redis_auto.sh ${1}
    bash ${SCRIPT_PATH}/mariadb/mariadb_auto.sh ${1}
    bash ${SCRIPT_PATH}/notebook/nb_auto.sh ${1}
    bash ${SCRIPT_PATH}/v2ray/v2ray_auto.sh ${1}
    bash ${SCRIPT_PATH}/shellinabox/sh_auto.sh ${1}
    bash ${SCRIPT_PATH}/nginx/nginx_auto.sh ${1}
    bash ${SCRIPT_PATH}/system/sys_auto.sh ${1}
    log_info "Uninstallation completed"
    exit 0
}

if [[ ${#} -lt 1 || ${#} -gt 2 || (${1} != 'install' && ${1} != 'uninstall') ]]; then
    help
elif [[ ${1} == 'uninstall' ]]; then
    auto_uninstall ${1}
elif [ ${#} -eq 2 ]; then
    SITE_NAME=${2}
else
    read -p "Enter site name: " SITE_NAME
fi

log_info "=== Begin to config vps automatically ..."
log_info "=== Note: You should run it at current user with sudo privilege."
log_info "=== Note: First, it will update your system and optimize vps instance."
log_info "===       Second, it will deploy nginx, shellinabox, v2ray, jupyter notebook mariadb and redis."
log_info "===       Third, it will download fhs-install-v2ray repository in workspace if not exists."
log_info "===       If you have not forked fhs-install-v2ray in your github repos, v2ray installation would fail."
log_info "===       If you have a domain name for the vps, it will config v2ray with websocket."
log_info "===       If you only have an ip address for the vps, then self-signed certificate could be generated."
log_info "===       Good luck!"

### System initialization
log_info "Starting system initialization..."
bash ${SCRIPT_PATH}/system/sys_auto.sh ${1}

### Install and config nginx
log_info "Installing and configuring nginx..."
bash ${SCRIPT_PATH}/nginx/nginx_auto.sh ${1} ${SITE_NAME}

### Install and config shellinabox
log_info "Installing and configuring shellinabox..."
bash ${SCRIPT_PATH}/shellinabox/sh_auto.sh ${1}

### Install and config v2ray
log_info "Installing and configuring v2ray..."
bash ${SCRIPT_PATH}/v2ray/v2ray_auto.sh ${1} ${SITE_NAME}

### Install and config jupyter notebook
log_info "Installing and configuring jupyter notebook..."
bash ${SCRIPT_PATH}/notebook/nb_auto.sh ${1}

### Install and config mariadb
log_info "Installing and configuring mariadb..."
bash ${SCRIPT_PATH}/mariadb/mariadb_auto.sh ${1}

### Install and config redis
log_info "Installing and configuring redis..."
bash ${SCRIPT_PATH}/redis/redis_auto.sh ${1}

### SET PASSWORD
log_info "***** CHANGE PASSWORD FOR root & ${CUR_USER} *****"
log_info "***** REBOOT PLEASE *****"
log_info "VPS configuration completed successfully!"

