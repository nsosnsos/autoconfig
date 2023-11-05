#!/usr/bin/env bash
#set -x
set -e

CUR_USER=$(whoami)
HOME_PATH=$(eval echo ~${CUR_USER})
SCRIPT_PATH=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SCRIPT_NAME=$(basename $(readlink -f "${0}"))
IDLE_LOAD=${HOME_PATH}/workspace/idle_load

### Check script parameters
if [[ ${#} -eq 1 && ${1} == "install" ]]; then
    if grep -Fq "personalized" ${HOME_PATH}/.bashrc; then
        echo "system is already initialized !!!"
        exit 0
    fi
elif [[ ${#} -eq 1 && ${1} == "uninstall" ]]; then
    if ! grep -Fq "personalized" ${HOME_PATH}/.bashrc; then
        echo "system is not initialized yet !!!"
        exit 0
    else
        rm -f ${HOME_PATH}/.gitconfig
        rm -f ${HOME_PATH}/.gitignore
        rm -f ${HOME_PATH}/.gitmessage
        rm -f ${HOME_PATH}/.vimrc
        rm -rf ${IDLE_LOAD}
        BASHRC_LINE_NO=$(($(sed -n -e'/personalized/=' ${HOME_PATH}/.bashrc) - 1))
        sed -i "1,${BASHRC_LINE_NO}!d" ${HOME_PATH}/.bashrc
        exit 0
    fi
else
    echo "Usage: ${SCRIPT_NAME} install/uninstall"
    exit -1
fi


### set hostname
read -p "Enter hostname: " HOSTNAME
echo "${HOSTNAME}" | sudo tee /etc/hostname > /dev/null

### enable password login
sudo sed -i "s/#PasswordAuthentication yes/PasswordAuthentication yes/g" /etc/ssh/sshd_config
### enable keepalive
sudo sed -i "s/#ClientAliveInterval 0/ClientAliveInterval 60/g" /etc/ssh/sshd_config
sudo sed -i "s/#ClientAliveCountMax 3/ClientAliveCountMax 0/g" /etc/ssh/sshd_config


### Update home config
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

### Add idle load
mkdir -p ${IDLE_LOAD}
cp ${SCRIPT_PATH}/idle.c ${IDLE_LOAD}/
gcc -o ${IDLE_LOAD}/idle ${IDLE_LOAD}/idle.c

### Set bash prompt
if ! grep -Fq "COLOR_NULL" ${HOME_PATH}/.bashrc; then
    cat >> ${HOME_PATH}/.bashrc <<EOF
# personalized prompt sign
COLOR_RED='\[\e[1;31m\]'
COLOR_NULL='\[\e[0m\]'
PS1="\$COLOR_RED[\u@\h \t] \w\$ \$COLOR_NULL"

# remove bash history after logout
rm -rf ~/.bash_history

# set idle load alias
alias idle='nohup ~/workspace/idle_load/idle > /dev/null 2>&1 &'

EOF
fi
if ! grep -Fq "bash_history" ${HOME_PATH}/.bash_logout; then
    cat >> ${HOME_PATH}/.bash_logout <<EOF

# remove bash history after logout
rm -rf ~/.bash_history

EOF
fi

### Update and install software
sudo apt update -y && sudo apt full-upgrade -y
sudo apt install -y net-tools ntpdate openssl python3-virtualenv tree

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
sudo apt purge netfilter-persistent -y

### Enable tcp bbr
modprobe tcp_bbr
if ! grep -Fq "tcp_bbr" /etc/modules-load.d/modules.conf; then
    echo "tcp_bbr" | sudo tee --append /etc/modules-load.d/modules.conf > /dev/null
fi
if ! grep -Fq "default_qdisc" /etc/sysctl.conf; then
    echo "net.core.default_qdisc=fq" | sudo tee --append /etc/sysctl.conf > /dev/null
fi
if ! grep -Fq "tcp_congestion_control" /etc/sysctl.conf; then
    echo "net.ipv4.tcp_congestion_control=bbr" | sudo tee --append /etc/sysctl.conf > /dev/null
fi
sudo sysctl -p
## verify tcp bbr
echo "Verify TCP BBR"
sysctl net.ipv4.tcp_available_congestion_control
sysctl net.ipv4.tcp_congestion_control
lsmod | grep bbr

