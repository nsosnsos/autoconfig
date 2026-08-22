#!/usr/bin/env bash
#set -x
set -e

CUR_USER=${SUDO_USER:-$(whoami)}
HOME_PATH=$(eval echo "~${CUR_USER}")
SCRIPT_PATH=$(dirname $(readlink -f "${BASH_SOURCE[0]}"))
SCRIPT_NAME=$(basename $(readlink -f "${BASH_SOURCE[0]}"))
source ${SCRIPT_PATH}/../logging.sh

if [[ ${#} -eq 1 && ${1} == "install" ]]; then
    if type shellinaboxd > /dev/null 2>&1 ; then
        log_info "shellinabox is already installed"
        exit 0
    fi
elif [[ ${#} -eq 1 && ${1} == "uninstall" ]]; then
    if type shellinaboxd > /dev/null 2>&1 ; then
        log_info "uninstalling shellinabox..."
        log_exec "sudo apt purge shellinabox -y"
        exit 0
    else
        log_info "shellinabox is not installed yet"
        exit 0
    fi
else
    log_error "Usage: ${SCRIPT_NAME} install/uninstall"
    exit 1
fi

### Install shellinabox
log_info "installing shellinabox..."
log_exec "sudo apt install shellinabox -y"

### Config shellinabox
log_info "configuring shellinabox..."
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

log_exec "sudo systemctl daemon-reload"
log_exec "sudo systemctl enable shellinabox"
log_exec "sudo systemctl restart shellinabox"
log_info "shellinabox installation completed successfully"

