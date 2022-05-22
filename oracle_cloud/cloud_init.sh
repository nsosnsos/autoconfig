#!/bin/bash
set -e
set -x

HOME_DIR=$(eval echo ~${SUDO_USER})
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

### Update home config
cp ${SCRIPT_DIR}/../.gitconfig ${HOME_DIR}/
cp ${SCRIPT_DIR}/../.gitignore ${HOME_DIR}/
cp ${SCRIPT_DIR}/../.gitmessage ${HOME_DIR}/
cp ${SCRIPT_DIR}/../.vimrc ${HOME_DIR}/

### Set bash prompt
cat >> ${HOME_DIR}/.bashrc <<EOF

# personalized prompt sign
COLOR_RED='\[\e[1;31m\]'
COLOR_NULL='\[\e[0m\]'
PS1="\$COLOR_RED[\u@\h \t] \w\$ \$COLOR_NULL"

EOF

### Update and install software
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install net-tools ntpdate shellinabox nginx -y

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

### Install and config v2ray
cd ${SCRIPT_DIR}/../v2ray
sudo bash v2ray_auto.sh
cd ${SCRIPT_DIR}

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

sudo systemctl enable shellinabox
sudo systemctl start shellinabox

### Config nginx

echo "***** CHANGE PASSWORD FOR root & ubuntu *****"
echo "***** REBOOT PLEASE *****"
