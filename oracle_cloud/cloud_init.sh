#!/bin/bash
#set -x
set -e

HOME_PATH=$(eval echo ~${SUDO_USER})
SCRIPT_PATH=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SCRIPT_NAME=$(basename $(readlink -f "${0}"))

CERT_PATH=${HOME_PATH}/cert
if [ ${#} -gt 1 ]; then
    echo "Usage: ${SCRIPT_NAME} [DOMAIN_NAME]"
    echo "       If DOMAIN_NAME is provided, then make sure legtimate certificate(site.cert/site.key) is provided in [${HOME_PATH}/cert/]."
    echo "       If DOMAIN_NAME is not provided, then v2ray would not be set to websocket."
    exit -1
elif [ ${#} -eq 1 ]; then
    DOMAIN_NAME=${1}
    V2RAY_CONFIG_FILE=v2ray_config_ws.json
else
    read -p "Enter nginx site name: " DOMAIN_NAME
    V2RAY_CONFIG_FILE=v2ray_config.json
fi

### Update home config
cp ${SCRIPT_PATH}/../.gitconfig ${HOME_PATH}/
cp ${SCRIPT_PATH}/../.gitignore ${HOME_PATH}/
cp ${SCRIPT_PATH}/../.gitmessage ${HOME_PATH}/
cp ${SCRIPT_PATH}/../.vimrc ${HOME_PATH}/

### Set bash prompt
cat >> ${HOME_PATH}/.bashrc <<EOF

# personalized prompt sign
COLOR_RED='\[\e[1;31m\]'
COLOR_NULL='\[\e[0m\]'
PS1="\$COLOR_RED[\u@\h \t] \w\$ \$COLOR_NULL"

EOF

### Update and install software
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install net-tools ntpdate openssl python3-virtualenv shellinabox nginx -y

### Set timezone and synchronize with ntp server
sudo ntpdate -u ntp.ubuntu.com
sudo timedatectl set-timezone "Asia/Hong_Kong"

### Config ssh
sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sudo sed -i 's/#TCPKeepAlive yes/TCPKeepAlive yes/g' /etc/ssh/sshd_config
sudo service ssh restart

### Stop firewall and disable route rules
sudo ufw disable
sudo iptables -P INPUT ACCEPT
sudo iptables -P FORWARD ACCEPT
sudo iptables -P OUTPUT ACCEPT
sudo iptables -F
sudo apt-get purge netfilter-persistent -y

### Enable tcp bbr
modprobe tcp_bbr
echo "tcp_bbr" | sudo tee --append /etc/modules-load.d/modules.conf
echo "net.core.default_qdisc=fq" | sudo tee --append /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" | sudo tee --append /etc/sysctl.conf
sudo sysctl -p
## verify tcp bbr
#sysctl net.ipv4.tcp_available_congestion_control
#sysctl net.ipv4.tcp_congestion_control
#lsmod | grep bbr

### Config jupyter notebook
NOTEBOOK_PATH=${HOME_PATH}/notebook
NOTEBOOK_WORK_PATH=${HOME_PATH}/${DOMAIN_NAME}/notebook
NOTEBOOK_CONFIG_FILE=${HOME_PATH}/.jupyter/jupyter_notebook_config.py

mkdir -p ${NOTEBOOK_PATH}
mkdir -p ${NOTEBOOK_WORK_PATH}
sudo chmod 777 ${NOTEBOOK_WORK_PATH}
virtualenv ${NOTEBOOK_PATH}
source ${NOTEBOOK_PATH}/bin/activate
pip3 install jupyter
jupyter notebook --generate-config
echo "[Set jupyter notebook password]"
jupyter notebook password
deactivate
sudo sed -i "s|# c.NotebookApp.ip = 'localhost'|c.NotebookApp.ip = '0.0.0.0'|g" ${NOTEBOOK_CONFIG_FILE}
sudo sed -i "s|# c.NotebookApp.port = 8888|c.NotebookApp.port = 4400|g" ${NOTEBOOK_CONFIG_FILE}
sudo sed -i "s|# c.NotebookApp.base_url = '/'|c.NotebookApp.base_url = '/nb'|g" ${NOTEBOOK_CONFIG_FILE}
sudo sed -i "s|# c.NotebookApp.allow_origin = ''|c.NotebookApp.allow_origin = '*'|g" ${NOTEBOOK_CONFIG_FILE}
echo "[Unit]
Description=Jupyter Notebook

[Service]
Type=simple
PIDFile=/run/notebook.pid
ExecStart=${NOTEBOOK_PATH}/bin/jupyter-notebook --config=${NOTEBOOK_CONFIG_FILE}
User=ubuntu
Group=ubuntu
WorkingDirectory=${NOTEBOOK_WORK_PATH}
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target" | sudo tee /etc/systemd/system/notebook.service > /dev/null

sudo systemctl daemon-reload
sudo systemctl enable notebook
sudo systemctl start notebook

### Config shellinabox
sudo cat > /etc/default/shellinabox <<EOF
# Should shellinaboxd start automatically
SHELLINABOX_DAEMON_START=1
# TCP port that shellinboxd's webserver listens on
SHELLINABOX_PORT=4200
# Any optional arguments (e.g. extra service definitions). Make sure
# that that argument is quoted.
#
#   Beeps are disabled because of reports of the VLC plugin crashing
#   Firefox on Linux/x86_64.
SHELLINABOX_ARGS="--no-beep --disable-ssl"
EOF

sudo systemctl daemon-reload
sudo systemctl enable shellinabox
sudo systemctl start shellinabox

### Install and config v2ray
bash ${SCRIPT_PATH}/../v2ray/v2ray_auto.sh ${SCRIPT_PATH}/../v2ray/${V2RAY_CONFIG_FILE}

### Config nginx
if [[ ! -d ${CERT_PATH} || ! -f ${CERT_PATH}/site.key || ! -f ${CERT_PATH}/site.cert ]]; then
    echo "Generating self signed certificate ..."
    mkdir -p ${CERT_PATH}
    openssl req -x509 -newkey rsa:4096 -nodes -out ${CERT_PATH}/site.cert -keyout ${CERT_PATH}/site.key -days 9999 -subj "/C=US/ST=California/L=SanJose/O=Global Security/OU=IT Department/CN=test@gmail.com"
fi
bash ${SCRIPT_PATH}/nginx_init.sh ${CERT_PATH} ${SCRIPT_PATH}/nginx.conf ${DOMAIN_NAME}

### SET PASSWORD
echo "***** CHANGE PASSWORD FOR root & ubuntu *****"
echo "***** REBOOT PLEASE *****"

