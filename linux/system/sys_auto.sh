#!/usr/bin/env bash
#set -x
set -e

CUR_USER=${SUDO_USER:-$(whoami)}
HOME_PATH=$(eval echo "~${CUR_USER}")
SCRIPT_PATH=$(dirname $(readlink -f "${BASH_SOURCE[0]}"))
SCRIPT_NAME=$(basename $(readlink -f "${BASH_SOURCE[0]}"))
source ${SCRIPT_PATH}/../logging.sh

### Check script parameters
if [[ ${#} -eq 1 && ${1} == "install" ]]; then
    if grep -Fq "personalized" ${HOME_PATH}/.bashrc; then
        log_info "system is already initialized"
        exit 0
    fi
elif [[ ${#} -eq 1 && ${1} == "uninstall" ]]; then
    if ! grep -Fq "personalized" ${HOME_PATH}/.bashrc; then
        log_info "system is not initialized yet"
        exit 0
    else
        log_info "Removing system configuration..."
        rm -f ${HOME_PATH}/.gitconfig
        rm -f ${HOME_PATH}/.gitignore
        rm -f ${HOME_PATH}/.gitmessage
        rm -f ${HOME_PATH}/.vimrc
        BASHRC_LINE_NO=$(($(sed -n -e'/personalized/=' ${HOME_PATH}/.bashrc) - 1))
        sed -i "1,${BASHRC_LINE_NO}!d" ${HOME_PATH}/.bashrc
        log_info "System configuration removed successfully"
        exit 0
    fi
else
    log_error "Usage: ${SCRIPT_NAME} install/uninstall"
    exit 1
fi


### set hostname
read -p "Enter hostname: " HOSTNAME
log_info "Setting hostname to ${HOSTNAME}..."
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
git config --global push.default simple
git config --global commit.template "~/.gitmessage"
cp ${SCRIPT_PATH}/../.gitignore ${HOME_PATH}/
cp ${SCRIPT_PATH}/../.gitmessage ${HOME_PATH}/
cp ${SCRIPT_PATH}/../.vimrc ${HOME_PATH}/

### Set bash prompt
if ! grep -Fq "COLOR_NULL" ${HOME_PATH}/.bashrc; then
    cat >> ${HOME_PATH}/.bashrc <<EOF
# personalized prompt sign
COLOR_RED='\[\e[1;31m\]'
COLOR_NULL='\[\e[0m\]'
PS1="\$COLOR_RED[\u@\h \t] \w\$ \$COLOR_NULL"

# remove bash history after logout
rm -rf ~/.bash_history

# set default editor to vim
export EDITOR=vim

EOF
fi
if ! grep -Fq "bash_history" ${HOME_PATH}/.bash_logout; then
    cat >> ${HOME_PATH}/.bash_logout <<EOF

# remove bash history after logout
rm -rf ~/.bash_history

EOF
fi

### Update and install software
log_info "Updating system packages..."
log_exec "sudo apt update -y && sudo apt full-upgrade -y"
log_exec "sudo apt install -y net-tools ntpdate openssl python3-virtualenv tree iptables"

### Set timezone and synchronize with ntp server
log_info "Setting timezone and synchronizing with NTP server..."
log_exec "sudo ntpdate -u ntp.ubuntu.com"
log_exec "sudo timedatectl set-timezone \"Asia/Hong_Kong\""

### Config ssh
log_info "Configuring SSH..."
sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sudo sed -i 's/#TCPKeepAlive yes/TCPKeepAlive yes/g' /etc/ssh/sshd_config
log_exec "sudo service ssh restart"

### Stop firewall and disable route rules
log_info "Configuring firewall..."
sudo iptables -P INPUT ACCEPT
sudo iptables -P FORWARD ACCEPT
sudo iptables -P OUTPUT ACCEPT
sudo iptables -F
log_exec "sudo apt purge netfilter-persistent -y"

### Enable tcp bbr
log_info "Enabling TCP BBR..."
log_exec "sudo modprobe tcp_bbr"
if ! grep -Fq "tcp_bbr" /etc/modules-load.d/modules.conf; then
    log_debug "Adding tcp_bbr to modules configuration..."
    echo "tcp_bbr" | sudo tee --append /etc/modules-load.d/modules.conf > /dev/null
fi
if ! grep -Fq "default_qdisc" /etc/sysctl.conf; then
    log_debug "Adding default qdisc configuration..."
    echo "net.core.default_qdisc=fq" | sudo tee --append /etc/sysctl.conf > /dev/null
fi
if ! grep -Fq "tcp_congestion_control" /etc/sysctl.conf; then
    log_debug "Adding TCP congestion control configuration..."
    echo "net.ipv4.tcp_congestion_control=bbr" | sudo tee --append /etc/sysctl.conf > /dev/null
fi
log_exec "sudo sysctl -p"
## verify tcp bbr
log_info "Verifying TCP BBR configuration..."
sysctl net.ipv4.tcp_available_congestion_control
sysctl net.ipv4.tcp_congestion_control
lsmod | grep bbr

### Enable crontab
log_info "Enabling cron service..."
log_exec "sudo systemctl start cron"
log_exec "sudo systemctl enable cron"

### Set journal log
log_info "Cleaning up journal logs..."
log_exec "sudo apt clean && sudo apt autoremove --purge -y"
log_exec "sudo journalctl --vacuum-size=100M"
log_exec "sudo journalctl --vacuum-time=3d"
log_info "System initialization completed successfully"

