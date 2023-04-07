#!/usr/bin/env bash
#set -x
set -e

CUR_USER=$(whoami)
HOME_PATH=$(eval echo ~${CUR_USER})
SCRIPT_PATH=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SCRIPT_NAME=$(basename $(readlink -f "${0}"))

### Check script parameters
if [[ ${#} == 1 && ${1} == "install" ]]; then
    if type redis-server > /dev/null 2>&1 ; then
        echo "redis is already installed !!!"
        exit 0
    fi
elif [[ ${#} == 1 && ${1} == "uninstall" ]]; then
    if type redis-server > /dev/null 2>&1 ; then
        echo "uninstalling redis ... !!!"
        sudo apt purge redis-server -y
        sudo apt autoremove -y
        exit 0
    else
        echo "redis is not installed yet !!!"
        exit 0
    fi
else
    echo "Usage: ${SCRIPT_NAME} install/uninstall"
    exit -1
fi

### Install redis-server
echo "installing redis ..."
sudo apt install redis-server -y

### Config redis-server
echo "configuring redis ..."

sudo systemctl daemon-reload
sudo systemctl enable redis-server
sudo systemctl restart redis-server

