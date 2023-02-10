#!/usr/bin/env bash
#set -x
set -e

HOME_PATH=$(eval echo ~${SUDO_USER})
SCRIPT_PATH=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SCRIPT_NAME=$(basename $(readlink -f "${0}"))

if [[ -f "${HOME_PATH}/.vimrc" ]]; then
    echo "system in already initialized !!!"
    exit 0
fi

### set hostname
read -p "Enter hostname: " HOSTNAME
echo "${HOSTNAME}" | sudo tee /etc/hostname > /dev/null

### enable password login
sudo sed -i "s/#PasswordAuthentication yes/PasswordAuthentication yes/g" /etc/ssh/sshd_config

### Update home config
cp ${SCRIPT_PATH}/../.gitconfig ${HOME_PATH}/
cp ${SCRIPT_PATH}/../.gitignore ${HOME_PATH}/
cp ${SCRIPT_PATH}/../.gitmessage ${HOME_PATH}/
cp ${SCRIPT_PATH}/../.vimrc ${HOME_PATH}/
read -p "Enter github mail address: " GITHUB_EMAIL
readarray -d @ -t str_array <<< "${GITHUB_EMAIL}"
GITHUB_USER="${str_array[0]}"
export GITHUB_USER
sudo sed -i "s/PARA_USER/${GITHUB_USER}/g" ${HOME_PATH}/.gitconfig
sudo sed -i "s/PARA_EMAIL/${GITHUB_EMAIL}/g" ${HOME_PATH}/.gitconfig

### Set bash prompt
if ! grep -Fq "COLOR_NULL" ${HOME_PATH}/.bashrc; then
    cat >> ${HOME_PATH}/.bashrc <<EOF

# personalized prompt sign
COLOR_RED='\[\e[1;31m\]'
COLOR_NULL='\[\e[0m\]'
PS1="\$COLOR_RED[\u@\h \t] \w\$ \$COLOR_NULL"

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

### Update and install software
sudo apt-get update -y && sudo apt-get upgrade -y
sudo apt-get install -y net-tools ntpdate openssl python3-virtualenv tree

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
#sysctl net.ipv4.tcp_congestion_control
lsmod | grep bbr

### Python virtual environment
PYTHON_ENV_PATH=${HOME_PATH}/python_env
sudo rm -rf ${PYTHON_ENV_PATH}
mkdir -p ${PYTHON_ENV_PATH}
virtualenv ${PYTHON_ENV_PATH}

