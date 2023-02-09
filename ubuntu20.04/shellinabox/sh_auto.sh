#!/usr/bin/env bash
#set -x
set -e

HOME_PATH=$(eval echo ~${SUDO_USER})
SCRIPT_PATH=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SCRIPT_NAME=$(basename $(readlink -f "${0}"))

if [[ ${#} -eq 1 && ${1} == "install" ]]; then
    if type shellinaboxd > /dev/null 2>&1 ; then
        echo "Shellinabox is already installed !!!"
        exit 0
    else
        echo "Installing shellinabox ..."
        sudo apt install shellinabox -y
    fi
elif [[ ${#} -eq 1 && ${1} == "uninstall" ]]; then
    if type shellinaboxd > /dev/null 2>&1 ; then
        echo "Uninstalling shellinabox ..."
        sudo apt purge shellinabox -y
        exit 0
    else
        echo "Shellinabox is not installed yet !!!"
        exit 0
    fi
else
    echo "Usage: ${SCRIPT_NAME} install/uninstall"
    exit -1
fi

### Config shellinabox
echo "Configure shellinabox ..."
echo "# Should shellinaboxd start automatically
SHELLINABOX_DAEMON_START=1
# TCP port that shellinboxd's webserver listens on
SHELLINABOX_PORT=4200
# Any optional arguments (e.g. extra service definitions). Make sure
# that that argument is quoted.
#
#   Beeps are disabled because of reports of the VLC plugin crashing
#   Firefox on Linux/x86_64.
SHELLINABOX_ARGS=\"--no-beep --disable-ssl\"" | sudo tee /etc/default/shellinabox > /dev/null

sudo systemctl daemon-reload
sudo systemctl enable shellinabox
sudo systemctl restart shellinabox

