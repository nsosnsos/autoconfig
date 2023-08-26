#!/usr/bin/env bash
#set -x
set -e

CUR_USER=$(whoami)
HOME_PATH=$(eval echo ~${CUR_USER})
SCRIPT_PATH=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SCRIPT_NAME=$(basename $(readlink -f "${0}"))

if [ ${#} -gt 1 ]; then
    echo "Usage: ${SCRIPT_NAME} [DOMAIN_NAME]"
    echo "Attention: DOMAIN_NAME is used for nginx server name."
    exit -1
elif [ ${#} -eq 1 ]; then
    DOMAIN_NAME=${1}
    V2RAY_CONFIG_FILE=v2ray_config_ws.json
else
    read -p "Enter domain name: " DOMAIN_NAME
    V2RAY_CONFIG_FILE=v2ray_config.json
fi

echo "=== Begin to config vps automatically ..."
echo "=== Note: You should run it at current user with sudo priviledge."
echo "===       First, it will update your system and optimize vps instance."
echo "===       Second, it will deploy nginx, shellinabox, v2ray, jupyter notebook mariadb and redis."
echo "===       Third, it will download fhs-install-v2ray repository in workspace if not exists."
echo "===       If you have not forked fhs-install-v2ray in your github repos, v2ray installation would fail."
echo "===       If you provide a domain name, it will config v2ray with websocket."
echo "===       If domain name is not provided, then self-signed certificate could be generated."
echo "===       Good luck !"

### System initialization
bash ${SCRIPT_PATH}/system/sys_auto.sh install

### Install and config nginx
bash ${SCRIPT_PATH}/nginx/nginx_auto.sh install ${DOMAIN_NAME}

### Install and config shellinabox
bash ${SCRIPT_PATH}/shellinabox/sh_auto.sh install

### Install and config v2ray
GITHUB_USER=$(git config user.name)
bash ${SCRIPT_PATH}/v2ray/v2ray_auto.sh install ${GITHUB_USER} ${SCRIPT_PATH}/v2ray/${V2RAY_CONFIG_FILE}

### Install and config jupyter notebook
bash ${SCRIPT_PATH}/notebook/nb_auto.sh install ${DOMAIN_NAME}

### Install and config mariadb
bash ${SCRIPT_PATH}/mariadb/mariadb_auto.sh install

### Install and config redis
bash ${SCRIPT_PATH}/redis/redis_auto.sh install

### SET PASSWORD
echo "***** CHANGE PASSWORD FOR root & ${CUR_USER} *****"
echo "***** REBOOT PLEASE *****"

