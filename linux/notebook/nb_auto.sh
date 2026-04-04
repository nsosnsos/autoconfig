#!/usr/bin/env bash
#set -x
set -e

CUR_USER=$(whoami)
HOME_PATH=$(eval echo ~${CUR_USER})
SCRIPT_PATH=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SCRIPT_NAME=$(basename $(readlink -f "${0}"))
source ${SCRIPT_PATH}/../logging.sh
NOTEBOOK_CONFIG_PATH=${HOME_PATH}/.jupyter
NOTEBOOK_CONFIG_FILE=${NOTEBOOK_CONFIG_PATH}/jupyter_notebook_config.py
NOTEBOOK_ENV_PATH=${NOTEBOOK_CONFIG_PATH}/python_env
HASH_PWD_SCRIPT="hash_passwd.py"

if [[ ${#} -eq 1 && ${1} == "install" ]]; then
    if [[ -d ${NOTEBOOK_CONFIG_PATH} ]]; then
        log_info "notebook is already installed"
        exit 0
    else
        NOTEBOOK_WORK_PATH=${NOTEBOOK_CONFIG_PATH}/notebook
    fi
elif [[ ${#} -eq 1 && ${1} == "uninstall" ]]; then
    if [[ -d ${NOTEBOOK_CONFIG_PATH} ]]; then
        log_info "uninstalling notebook ..."
        source ${NOTEBOOK_ENV_PATH}/bin/activate
        log_exec "pip3 uninstall jupyter -y"
        log_exec "sudo rm -rf ${NOTEBOOK_CONFIG_PATH}"
        exit 0
    else
        log_info "notebook is not installed yet"
        exit 0
    fi
else
    log_error "Usage: ${SCRIPT_NAME} install/uninstall"
    exit 1
fi

### Install notebook
log_info "installing notebook..."
mkdir -p ${NOTEBOOK_ENV_PATH}
log_exec "virtualenv ${NOTEBOOK_ENV_PATH}"
source ${NOTEBOOK_ENV_PATH}/bin/activate
log_exec "pip3 install jupyter"

### Config notebook
log_info "configuring notebook..."
log_exec "sudo mkdir -p ${NOTEBOOK_WORK_PATH}"
log_exec "sudo chown ${CUR_USER}:${CUR_USER} ${NOTEBOOK_WORK_PATH}"
log_exec "sudo chmod 777 ${NOTEBOOK_WORK_PATH}"

log_debug "Generating jupyter notebook configuration..."
echo "y" | jupyter notebook --generate-config
log_debug "Configuring jupyter notebook settings..."
sed -i "s|# c.ServerApp.ip = 'localhost'|c.ServerApp.ip = '0.0.0.0'|g" ${NOTEBOOK_CONFIG_FILE}
sed -i "s|# c.ServerApp.port = 0|c.ServerApp.port = 4400|g" ${NOTEBOOK_CONFIG_FILE}
sed -i "s|# c.ServerApp.base_url = '/'|c.ServerApp.base_url = '/nb'|g" ${NOTEBOOK_CONFIG_FILE}
sed -i "s|# c.ServerApp.allow_origin = ''|c.ServerApp.allow_origin = '*'|g" ${NOTEBOOK_CONFIG_FILE}
sed -i "s|# c.ServerApp.tornado_settings = {}|c.ServerApp.tornado_settings = {\"websocket_max_message_size\": 1024 * 1024 * 1024}|g" ${NOTEBOOK_CONFIG_FILE}

read -s -p "[Set jupyter notebook password]" NOTEBOOK_PASSWD
echo ""
#HASHED_NOTEBOOK_PASSWD="SHA256:$(echo -n ${NOTEBOOK_PASSWD} | sha256sum | awk '{'print $1'})"
log_debug "Hashing notebook password..."
HASHED_NOTEBOOK_PASSWD=$(${SCRIPT_PATH}/${HASH_PWD_SCRIPT} ${NOTEBOOK_PASSWD})
if ! grep -Fq "PasswordConfiguration" ${NOTEBOOK_CONFIG_FILE}; then
    log_debug "Adding password configuration to notebook config..."
    cat >> ${NOTEBOOK_CONFIG_FILE} << EOF

## PasswordConfiguration
c.ServerApp.identity_provider_class = 'jupyter_server.auth.identity.PasswordIdentityProvider'
c.ServerApp.PasswordIdentityProvider.password_required = True
c.ServerApp.PasswordIdentityProvider.allow_password_change = True
c.ServerApp.PasswordIdentityProvider.hashed_password = '${HASHED_NOTEBOOK_PASSWD}'

EOF
fi

log_debug "Creating systemd service for jupyter notebook..."
echo "[Unit]
Description=Jupyter Notebook
[Service]
Type=simple
PIDFile=/run/notebook.pid
ExecStart=${NOTEBOOK_ENV_PATH}/bin/jupyter-notebook --config=${NOTEBOOK_CONFIG_FILE}
User=${CUR_USER}
Group=${CUR_USER}
WorkingDirectory=${NOTEBOOK_WORK_PATH}
Restart=always
RestartSec=10
[Install]
WantedBy=multi-user.target" | sudo tee /etc/systemd/system/notebook.service > /dev/null > /dev/null

log_exec "sudo systemctl daemon-reload"
log_exec "sudo systemctl enable notebook"
log_exec "sudo systemctl restart notebook"
deactivate
log_info "jupyter notebook installation completed successfully"

