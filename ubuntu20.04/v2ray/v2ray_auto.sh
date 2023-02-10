#!/usr/bin/env bash
#set -x
set -e

HOME_PATH=$(eval echo ~${SUDO_USER})
SCRIPT_PATH=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SCRIPT_NAME=$(basename $(readlink -f "${0}"))
WORK_DIR=workspace
V2RAY_REPO=fhs-install-v2ray
V2RAY_DIR=${HOME_PATH}/${WORK_DIR}/${V2RAY_REPO}

if [[ ${#} -eq 3 && ${1} == "install" ]]; then
    if type v2ray > /dev/null 2>&1 ; then
        echo "V2ray is already installed !!!"
        exit 0
    else
        if [ ! -f ${CONF_FILE} ]; then
            echo "Non-existing v2ray config file !!!"
            exit -1
        fi
        GITHUB_USER=${2}
        CONF_FILE=${3}
    fi
elif [[ ${#} -eq 1 && ${1} == "uninstall" ]]; then
    if type v2ray > /dev/null 2>&1 ; then
        echo "Uninstalling v2ray ..."
        sudo bash ${V2RAY_DIR}/install-release.sh --remove
        sudo systemctl disable v2ray
        sudo rm -rf /usr/local/etc/v2ray /var/log/v2ray
        exit 0
    else
        echo "V2ray is not installed yet !!!"
        exit 0
    fi
else
    echo "Usage: ${SCRIPT_NAME} install/uninstall [GITHUB_USER] [CONF_FILE]"
    echo "       You should have repo at git@github.com:[GITHUB_USER]/${V2RAY_REPO}.git first !!!"
    exit -1
fi

if [ ! -d ${V2RAY_DIR} ]; then
    echo "Downloading ${V2RAY_REPO} repository, you should have forked ${V2RAY_REPO}!"
    mkdir -p ${HOME_PATH}/${WORK_DIR}
    cd ${HOME_PATH}/${WORK_DIR}
    git clone git@github.com:${GITHUB_USER}/${V2RAY_REPO}.git
    cd -
fi

sudo bash ${V2RAY_DIR}/install-release.sh
sudo bash ${V2RAY_DIR}/install-dat-release.sh

sudo cp ${CONF_FILE} /usr/local/etc/v2ray/config.json
echo "Default v2ray id: 00000000-0000-0000-0000-000000000000"
echo "Please modify to v2ray config id by [uuidgen]"
read -p "Enter v2ray id: " V2RAY_ID
sudo sed -i "s|00000000-0000-0000-0000-000000000000|${V2RAY_ID}|g" /usr/local/etc/v2ray/config.json
sudo systemctl restart v2ray

