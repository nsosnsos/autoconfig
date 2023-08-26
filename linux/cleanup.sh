#!/usr/bin/env bash
#set -x
set -e

CUR_USER=$(whoami)
HOME_PATH=$(eval echo ~${CUR_USER})
SCRIPT_PATH=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SCRIPT_NAME=$(basename $(readlink -f "${0}"))

### System config remains, only remove bash and git config
echo "cleanup system config ..."
bash ${SCRIPT_PATH}/system/sys_auto.sh uninstall

### Install and config nginx
echo "cleanup nginx ..."
bash ${SCRIPT_PATH}/nginx/nginx_auto.sh uninstall

### Install and config shellinabox
echo "cleanup shellinabox ..."
bash ${SCRIPT_PATH}/shellinabox/sh_auto.sh uninstall

### Install and config v2ray
echo "cleanup v2ray ..."
bash ${SCRIPT_PATH}/v2ray/v2ray_auto.sh uninstall

### Install and config jupyter notebook
echo "cleanup notebook ..."
bash ${SCRIPT_PATH}/notebook/nb_auto.sh uninstall

### Install and config mariadb
echo "cleanup mariadb ..."
bash ${SCRIPT_PATH}/mariadb/mariadb_auto.sh uninstall

### Install and config redis
echo "cleanup redis ..."
bash ${SCRIPT_PATH}/redis/redis_auto.sh uninstall

