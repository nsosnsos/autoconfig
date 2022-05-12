#!/bin/bash
set -e
set -x
                                                                                                                                                                                                                   
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install net-tools shellinabox
sudo ufw disable

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

HOME_DIR=$(eval echo ~${SUDO_USER})
cat >> ${HOME_DIR}/.bashrc <<EOF

# personalized prompt sign
COLOR_RED='\[\e[1;31m\]'
COLOR_NULL='\[\e[0m\]'
PS1="\$COLOR_RED[\u@\h \t] \w\$ \$COLOR_NULL"

EOF

sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sudo service ssh restart

