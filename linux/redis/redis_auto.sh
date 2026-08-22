#!/usr/bin/env bash
#set -x
set -e

CUR_USER=${SUDO_USER:-$(whoami)}
HOME_PATH=$(eval echo "~${CUR_USER}")
SCRIPT_PATH=$(dirname $(readlink -f "${BASH_SOURCE[0]}"))
SCRIPT_NAME=$(basename $(readlink -f "${BASH_SOURCE[0]}"))
source ${SCRIPT_PATH}/../logging.sh

### Check script parameters
if [[ ${#} == 1 && ${1} == "install" ]]; then
    if type redis-server > /dev/null 2>&1 ; then
        log_info "redis is already installed"
        exit 0
    fi
elif [[ ${#} == 1 && ${1} == "uninstall" ]]; then
    if type redis-server > /dev/null 2>&1 ; then
        log_info "uninstalling redis..."
        log_exec "sudo apt purge redis-server -y"
        log_exec "sudo apt autoremove -y"
        exit 0
    else
        log_info "redis is not installed yet"
        exit 0
    fi
else
    log_error "Usage: ${SCRIPT_NAME} install/uninstall"
    exit 1
fi

### Install redis-server
log_info "installing redis..."
log_exec "sudo apt install redis-server -y"

### Config redis-server
log_info "configuring redis..."

log_exec "sudo systemctl daemon-reload"
log_exec "sudo systemctl enable redis-server"
log_exec "sudo systemctl restart redis-server"
log_info "redis installation completed successfully"

