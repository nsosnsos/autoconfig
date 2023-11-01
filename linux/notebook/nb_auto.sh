#!/usr/bin/env bash
#set -x
set -e

CUR_USER=$(whoami)
HOME_PATH=$(eval echo ~${CUR_USER})
SCRIPT_PATH=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SCRIPT_NAME=$(basename $(readlink -f "${0}"))
NOTEBOOK_CONFIG_PATH=${HOME_PATH}/.jupyter
NOTEBOOK_CONFIG_FILE=${NOTEBOOK_CONFIG_PATH}/jupyter_notebook_config.py
NOTEBOOK_ENV_PATH=${NOTEBOOK_CONFIG_PATH}/python_env
HASH_PWD_SCRIPT="hash_passwd.py"

if [[ ${#} -eq 1 && ${1} == "install" ]]; then
    if [[ -d ${NOTEBOOK_CONFIG_PATH} ]]; then
        echo "notebook is already installed !!!"
        exit 0
    else
        NOTEBOOK_WORK_PATH=${NOTEBOOK_CONFIG_PATH}/notebook
    fi
elif [[ ${#} -eq 1 && ${1} == "uninstall" ]]; then
    if [[ -d ${NOTEBOOK_CONFIG_PATH} ]]; then
        echo "uninstalling notebook ..."
        source ${NOTEBOOK_ENV_PATH}/bin/activate
        pip3 uninstall jupyter -y
        sudo rm -rf ${NOTEBOOK_CONFIG_PATH}
        exit 0
    else
        echo "notebook is not installed yet !!!"
        exit 0
    fi
else
    echo "Usage: ${SCRIPT_NAME} install/uninstall"
    exit -1
fi

### Install notebook
echo "installing notebook ..."
mkdir -p ${NOTEBOOK_ENV_PATH}
virtualenv ${NOTEBOOK_ENV_PATH}
source ${NOTEBOOK_ENV_PATH}/bin/activate
pip3 install jupyter

### Config notebook
echo "configuring notebook ..."
sudo mkdir -p ${NOTEBOOK_WORK_PATH}
sudo chown ${CUR_USER}:${CUR_USER} ${NOTEBOOK_WORK_PATH}
sudo chmod 777 ${NOTEBOOK_WORK_PATH}

echo "y" | jupyter notebook --generate-config
sed -i "s|# c.ServerApp.ip = 'localhost'|c.ServerApp.ip = '0.0.0.0'|g" ${NOTEBOOK_CONFIG_FILE}
sed -i "s|# c.ServerApp.port = 0|c.ServerApp.port = 4400|g" ${NOTEBOOK_CONFIG_FILE}
sed -i "s|# c.ServerApp.base_url = '/'|c.ServerApp.base_url = '/nb'|g" ${NOTEBOOK_CONFIG_FILE}
sed -i "s|# c.ServerApp.allow_origin = ''|c.ServerApp.allow_origin = '*'|g" ${NOTEBOOK_CONFIG_FILE}
sed -i "s|# c.ServerApp.tornado_settings = {}|c.ServerApp.tornado_settings = {\"websocket_max_message_size\": 1024 * 1024 * 1024}|g" ${NOTEBOOK_CONFIG_FILE}

read -p "[Set jupyter notebook password]" -s NOTEBOOK_PASSWD
echo ""
#HASHED_NOTEBOOK_PASSWD="SHA256:$(echo -n ${NOTEBOOK_PASSWD} | sha256sum | awk '{print $1}')"
HASHED_NOTEBOOK_PASSWD=$(${SCRIPT_PATH}/${HASH_PWD_SCRIPT} ${NOTEBOOK_PASSWD})
if ! grep -Fq "PasswordConfiguration" ${NOTEBOOK_CONFIG_FILE}; then
    cat >> ${NOTEBOOK_CONFIG_FILE} << EOF

## PasswordConfiguration
c.ServerApp.identity_provider_class = 'jupyter_server.auth.identity.PasswordIdentityProvider'
c.ServerApp.PasswordIdentityProvider.password_required = True
c.ServerApp.PasswordIdentityProvider.allow_password_change = True
c.ServerApp.PasswordIdentityProvider.hashed_password = '${HASHED_NOTEBOOK_PASSWD}'

EOF
fi

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

sudo systemctl daemon-reload
sudo systemctl enable notebook
sudo systemctl restart notebook
deactivate

