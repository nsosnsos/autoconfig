#!/usr/bin/env bash
#set -x
#set -e

CUR_USER=$(whoami)
HOME_PATH=$(eval echo ~${CUR_USER})
SCRIPT_PATH=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SCRIPT_NAME=$(basename $(readlink -f "${0}"))
source ${SCRIPT_PATH}/logging.sh

if [[ ${#} -eq 1 ]]; then
    SITE_NAME=${1}
else
    log_error "Usage: ${SCRIPT_NAME} SITE_NAME"
    exit 1
fi

### System config remains, only remove bash and git config
log_info "cleanup system config ..."
bash ${SCRIPT_PATH}/system/sys_auto.sh uninstall

### Install and config nginx
log_info "cleanup nginx ..."
bash ${SCRIPT_PATH}/nginx/nginx_auto.sh uninstall ${SITE_NAME}

### Install and config shellinabox
log_info "cleanup shellinabox ..."
bash ${SCRIPT_PATH}/shellinabox/sh_auto.sh uninstall

### Install and config v2ray
log_info "cleanup v2ray ..."
bash ${SCRIPT_PATH}/v2ray/v2ray_auto.sh uninstall

### Install and config jupyter notebook
log_info "cleanup notebook ..."
bash ${SCRIPT_PATH}/notebook/nb_auto.sh uninstall

### Install and config mariadb
log_info "cleanup mariadb ..."
bash ${SCRIPT_PATH}/mariadb/mariadb_auto.sh uninstall

### Install and config redis
log_info "cleanup redis ..."
bash ${SCRIPT_PATH}/redis/redis_auto.sh uninstall

log_info "cleanup completed successfully"

