#!/usr/bin/env bash
#set -x
set -e


CUR_USER=$(whoami)
HOME_PATH=$(eval echo ~${CUR_USER})
SCRIPT_PATH=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SCRIPT_NAME=$(basename $(readlink -f "${0}"))
WORK_PATH=${HOME_PATH}/Workspace
PYTHON_ENV_PATH=${HOME_PATH}/.python_env


### remove unnecessary services
# remove braille display service
sudo systemctl stop brltty.service
sudo systemctl disable brltty.service
# remove smtp service
sudo apt purge -y exim4-base exim4-config exim4-daemon-light

### add apt repository mirror
if ! grep -Fq "tsinghua" /etc/apt/sources.list; then
    sudo chmod 666 /etc/apt/sources.list
    sudo sed -i 's|^deb|# &|g' /etc/apt/sources.list
    sudo cat >> /etc/apt/sources.list <<EOF
# deb https://mirrors.tuna.tsinghua.edu.cn/raspbian/raspbian/ bullseye main contrib non-free rpi
deb [arch=arm64] https://mirrors.tuna.tsinghua.edu.cn/raspbian/multiarch/ bullseye main
EOF
    sudo chmod 644 /etc/apt/sources.list
fi

### remove raspberry repository source
if ! grep -Fq "tsinghua" /etc/apt/sources.list.d/raspi.list; then
    sudo chmod 666 /etc/apt/sources.list.d/raspi.list
    sudo sed -i 's|^deb|# &|g' /etc/apt/sources.list.d/raspi.list
    sudo cat >> /etc/apt/sources.list.d/raspi.list <<EOF
deb http://mirrors.tuna.tsinghua.edu.cn/raspberrypi/ bullseye main
EOF
    sudo chmod 644 /etc/apt/sources.list.d/raspi.list
fi

### need manual config for gpg key
echo "IMPORTANT: YOU MAY NEED MANUALLY CONFIG GPG KEY !"
echo "gpg --keyserver keyserver.ubuntu.com --recv-keys 123456789"
echo "gpg --export --armor 123456789 | sudo apt-key add -"

### update and upgrade
sudo apt update -y && sudo apt full-upgrade -y
sudo apt autoremove -y
sudo apt autopurge -y

### install necessary software
sudo apt --reinstall install -y libraspberrypi-bin
sudo apt install -y vim tree net-tools ntpdate ca-certificates
sudo apt install -y libblockdev-crypto2 libblockdev-mdraid2 accountsservice
sudo apt install -y openssl python3-virtualenv
sudo apt install -y fcitx-googlepinyin

### vim config
#sudo apt install -y vim vim-scripts vim-doc vim-addon-manager
#vim-addons install omnicppcomplete
#vim-addons install minibufexplorer
#vim-addons install winmanager
#vim-addons install project

### enable password login
sudo sed -i "s/#PasswordAuthentication yes/PasswordAuthentication yes/g" /etc/ssh/sshd_config
sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sudo sed -i 's/#TCPKeepAlive yes/TCPKeepAlive yes/g' /etc/ssh/sshd_config
sudo service ssh restart

### set timezone and synchronize with ntp server
sudo ntpdate -u ntp.ubuntu.com
sudo timedatectl set-timezone "Asia/Hong_Kong"

### set git config
read -p "Enter github mail address: " GITHUB_EMAIL
readarray -d @ -t str_array <<< "${GITHUB_EMAIL}"
GITHUB_USER="${str_array[0]}"
git config --global user.name "${GITHUB_USER}"
git config --global user.email "${GITHUB_EMAIL}"
git config --global color.ui true
git config --global core.editor vim
git config --global core.quotepath false
git config --global core.autocrlf false
git config --global core.excludesfile "~/.gitignore"
git config --global pull.rebase true
git config --global merge.tool vimdiff
git config --global i18n.commitencoding utf-8
git config --global i18n.logoutputencoding utf-8
git config --global credential.helper "store --file ~/.git-credentials"
git config --global push.default simple
git config --global commit.template "~/.gitmessage"
cp ${SCRIPT_PATH}/../.gitignore ${HOME_PATH}/
cp ${SCRIPT_PATH}/../.gitmessage ${HOME_PATH}/
cp ${SCRIPT_PATH}/../.vimrc ${HOME_PATH}/

### set bash prompt
if ! grep -Fq "COLOR_NULL" ${HOME_PATH}/.bashrc; then
    cat >> ${HOME_PATH}/.bashrc <<EOF

# personalized prompt sign
COLOR_RED='\[\e[1;31m\]'
COLOR_NULL='\[\e[0m\]'
PS1="\$COLOR_RED[\u@\h \t] \w\$ \$COLOR_NULL"

# add alias
alias ll='ls -la'
alias chrome='nohup chromium-browser --proxy-server=\"socks5://127.0.0.1:20170\" > /dev/null 2>&1 &'

# remove bash history after logout
rm -rf ~/.bash_history

EOF
fi
if ! grep -Fq "bash_history" ${HOME_PATH}/.bash_logout; then
    cat >> ${HOME_PATH}/.bash_logout <<EOF

# remove bash history after logout
rm -rf ~/.bash_history

EOF
fi

### python virtual environment
if [[ ! -d ${PYTHON_ENV_PATH} ]]; then
    sudo rm -rf ${PYTHON_ENV_PATH}
    mkdir -p ${PYTHON_ENV_PATH}
    virtualenv ${PYTHON_ENV_PATH}
fi

### add pip repository mirror 
if ! grep -Fq "tsinghua" /etc/pip.conf; then
    sudo chmod 666 /etc/pip.conf
    sudo cat > /etc/pip.conf <<EOF
[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple
trusted-host = pypi.tuna.tsinghua.edu.cn
extra-index-url = https://www.piwheels.org/simple https://pypi.org/simple/
EOF
    sudo chmod 644 /etc/pip.conf
fi

### set system proxy
sudo cat > ${WORK_PATH}/proxy.sh <<EOF
export http_proxy="socks5://127.0.0.1:20170"
export https_proxy="socks5://127.0.0.1:20170"
export no_proxy="localhost, 127.0.0.1, 192.168.*"
EOF
chmod u+x ${WORK_PATH}/proxy.sh

### disable cursor
sudo apt install unclutter -y
sudo cat > ${HOME_PATH}/.config/lxpanel/LXDE-pi/autostart <<EOF
@lxpanel --profile LXDE
@unclutter -idle 0
EOF

### install v2ray and v2raya
if ! service --status-all | grep -Fq 'v2raya'; then
    curl -Ls https://mirrors.v2raya.org/go.sh | sudo bash
    sudo systemctl disable v2ray --now
    wget -qO - https://apt.v2raya.org/key/public-key.asc | sudo tee /etc/apt/trusted.gpg.d/v2raya.asc
    echo "deb https://apt.v2raya.org/ v2raya main" | sudo tee /etc/apt/sources.list.d/v2raya.list
    sudo apt update -y
    sudo apt install v2raya -y
    sudo systemctl enable v2raya.service
    sudo systemctl start v2raya.service
fi

# update firmware
sudo rpi-update
sudo rpi-eeprom-update -a

