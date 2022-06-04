#!/usr/bin/env bash
set -e
set -x

HOME_PATH=$(eval echo ~${SUDO_USER})
SCRIPT_PATH=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SCRIPT_NAME=$(basename $(readlink -f "${0}"))

if [ ${#} != 1 ]; then
    echo "Wrong parameters !!!"
    echo "Usage ${SCRIPT_NAME} CONF_FILE"
    exit -1
fi

if [ ! -f ${1} ]; then
    echo "Non-existing v2ray config file !!!"
    exit -1
fi

sudo bash ${SCRIPT_PATH}/v2ray_install.sh
sudo bash ${SCRIPT_PATH}/v2ray_dat_install.sh

sudo cp ${1} /usr/local/etc/v2ray/config.json
sudo systemctl restart v2ray

