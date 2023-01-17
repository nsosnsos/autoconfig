#!/usr/bin/env bash
#set -x
set -e

HOME_PATH=$(eval echo ~${SUDO_USER})
SCRIPT_PATH=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SCRIPT_NAME=$(basename $(readlink -f "${0}"))
V2RAY_DIR=${HOME_PATH}/workspace/fhs-install-v2ray

if [ ${#} != 1 ]; then
    echo "Wrong parameters !!!"
    echo "Usage ${SCRIPT_NAME} CONF_FILE"
    exit -1
fi

if [ ! -f ${1} ]; then
    echo "Non-existing v2ray config file !!!"
    exit -1
fi

if [ ! -d ${V2RAY_DIR} ]; then
    echo "Please download fhs-install-v2ray repository first !!!"
    echo "STEP1: cd ~/workspace"
    echo "STEP2: git clone git@github.com:nsosnsos/fhs-install-v2ray.git"
    exit -1
fi

sudo bash ${V2RAY_DIR}/install-release.sh
sudo bash ${V2RAY_DIR}/install-dat-release.sh

sudo cp ${1} /usr/local/etc/v2ray/config.json
echo "Default v2ray id: 00000000-0000-0000-0000-000000000000"
echo "Please modify to v2ray config id by [uuidgen]"
read -p "Enter v2ray id: " V2RAY_ID
sudo sed -i "s|00000000-0000-0000-0000-000000000000|${V2RAY_ID}|g" /usr/local/etc/v2ray/config.json
sudo systemctl restart v2ray

