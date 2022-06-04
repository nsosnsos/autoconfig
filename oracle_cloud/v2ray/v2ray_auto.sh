#!/usr/bin/env bash
#set -x
set -e

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
echo "Default v2ray id: 00000000-0000-0000-0000-000000000000"
echo "Please modify to v2ray config id by [uuidgen]"
read -p "Enter v2ray id: " V2RAY_ID
sudo sed -i "s|00000000-0000-0000-0000-000000000000|${V2RAY_ID}|g" /usr/local/etc/v2ray/config.json
sudo systemctl restart v2ray

