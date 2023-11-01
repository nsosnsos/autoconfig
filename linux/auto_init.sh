#!/usr/bin/env bash
#set -x
set -e

CUR_USER=$(whoami)
HOME_PATH=$(eval echo ~${CUR_USER})
SCRIPT_PATH=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SCRIPT_NAME=$(basename $(readlink -f "${0}"))


function help () {
    echo "Usage: ${SCRIPT_NAME} [install|uninstall] [SITE_NAME]"
    echo "Attention: SITE_NAME is used for nginx server name."
    echo "           It could be a domain name or an ip address."
    exit -1
}

function auto_uninstall () {
    bash ${SCRIPT_PATH}/redis/redis_auto.sh ${1}
    bash ${SCRIPT_PATH}/mariadb/mariadb_auto.sh ${1}
    bash ${SCRIPT_PATH}/notebook/nb_auto.sh ${1}
    bash ${SCRIPT_PATH}/v2ray/v2ray_auto.sh ${1}
    bash ${SCRIPT_PATH}/shellinabox/sh_auto.sh ${1}
    bash ${SCRIPT_PATH}/nginx/nginx_auto.sh ${1}
    bash ${SCRIPT_PATH}/system/sys_auto.sh ${1}
    exit -1
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

echo "=== Begin to config vps automatically ..."
echo "=== Note: You should run it at current user with sudo priviledge."
echo "=== Note: First, it will update your system and optimize vps instance."
echo "===       Second, it will deploy nginx, shellinabox, v2ray, jupyter notebook mariadb and redis."
echo "===       Third, it will download fhs-install-v2ray repository in workspace if not exists."
echo "===       If you have not forked fhs-install-v2ray in your github repos, v2ray installation would fail."
echo "===       If you have a domain name for the vps, it will config v2ray with websocket."
echo "===       If you only have an ip address for the vps, then self-signed certificate could be generated."
echo "===       Good luck !"

### System initialization
bash ${SCRIPT_PATH}/system/sys_auto.sh ${1}

### Install and config nginx
bash ${SCRIPT_PATH}/nginx/nginx_auto.sh ${1} ${SITE_NAME}

### Install and config shellinabox
bash ${SCRIPT_PATH}/shellinabox/sh_auto.sh ${1}

### Install and config v2ray
bash ${SCRIPT_PATH}/v2ray/v2ray_auto.sh ${1} ${SITE_NAME}

### Install and config jupyter notebook
bash ${SCRIPT_PATH}/notebook/nb_auto.sh ${1}

### Install and config mariadb
bash ${SCRIPT_PATH}/mariadb/mariadb_auto.sh ${1}

### Install and config redis
bash ${SCRIPT_PATH}/redis/redis_auto.sh ${1}

### SET PASSWORD
echo "***** CHANGE PASSWORD FOR root & ${CUR_USER} *****"
echo "***** REBOOT PLEASE *****"

