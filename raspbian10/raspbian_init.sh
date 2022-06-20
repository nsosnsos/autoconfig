#!/usr/bin/env bash

sudo chmod 666 /etc/apt/sources.list
sudo echo deb https://mirrors.tuna.tsinghua.edu.cn/raspbian/raspbian/ buster main contrib non-free rpi > /etc/apt/sources.list
sudo chmod 644 /etc/apt/sources.list
sudo chmod 666 /etc/apt/sources.list.d/raspi.list
sudo echo # deb https://archive.raspberrypi.org/debian/ buster main > /etc/apt/sources.list.d/raspi.list
sudo echo # deb-src https://archive.raspberrypi.org/debian/ buster main >> /etc/apt/sources.list.d/raspi.list
sudo chmod 644 /etc/apt/sources.list.d/raspi.list
sudo apt-get update && sudo apt-get dist-upgrade -y
sudo apt-get autoremove
sudo rpi-update
sudo rpi-eeprom-update -a

sudo passwd root
su root
exit

sudo apt-get install -y xrdp
sudo apt-get install -y ntpdate
sudo ntpdate -u ntp.ubuntu.com

sudo apt-get install -y ttf-wqy-zenhei ttf-wqy-microhei xfonts-wqy
sudo apt-get install -y fcitx fcitx-googlepinyin fcitx-module-cloudpinyin fcitx-sunpinyin

sudo apt-get install -y vim vim-scripts vim-doc vim-addon-manager
sudo apt-get install -y ctags cscope tree
vim-addons install omnicppcomplete
vim-addons install minibufexplorer
vim-addons install winmanager
vim-addons install project
vim-addons install taglist

sudo chmod 666 /etc/pip.conf
sudo echo [global] > /etc/pip.conf
sudo echo index-url = https://pypi.tuna.tsinghua.edu.cn/simple >> /etc/pip.conf
sudo echo trusted-host = pypi.tuna.tsinghua.edu.cn >> /etc/pip.conf
sudo echo extra-index-url = https://www.piwheels.org/simple https://pypi.org/simple/ >> /etc/pip.conf
sudo chmod 644 /etc/pip.conf

sudo apt-get install -y python3-pip
sudo pip3 install --upgrade pip
rm -rf /usr/bin/pip3
ln -s /usr/local/bin/pip3 /usr/bin/pip3

sudo apt-get install -y python3-dev libxml2-dev libxslt1-dev zlib1g-dev libhdf5-dev libblas-dev liblapack-dev libatlas-base-dev gfortran
sudo pip3 install wrapt --ignore-installed
sudo pip3 install pandas numpy scipy tensorflow matplotlib

read -p "Input user name for github: " PARA_USER
read -p "Input user email for github: " PARA_EMAIL
ssh-keygen -t rsa -d 4096 -C "${PARA_EMAIL}"
cp ~/.ssh/id_rsa.pub ~/.ssh/authorized_keys

git config --global user.name "${PARA_USER}"
git config --global user.email "${PARA_EMAIL}"
git config --global credential.helper store
git config --global commit.template ~/.gitmessage
git config --global core.excludesFile ~/.gitignore
git config --global core.editor vim
git config --global merge.tool vimdiff

sudo apt-get install -y nginx
sudo rm -rf /etc/nginx/sites-available/* /etc/nginx/sites-enabled/*
sudo systemctl enable nginx
sudo ststemctl start nginx

sudo apt-get install -y shellinabox
sudo cat > /etc/default/shellinabox <<EOF
# Should shellinaboxd start automatically
SHELLINABOX_DAEMON_START=1
# TCP port that shellinboxd's webserver listens on
SHELLINABOX_PORT=8080
# Any optional arguments (e.g. extra service definitions). Make sure
# that that argument is quoted.
#
#   Beeps are disabled because of reports of the VLC plugin crashing
#   Firefox on Linux/x86_64.
SHELLINABOX_ARGS="--no-beep --disable-ssl "
EOF
sudo systemctl enable shellinabox
sudo systemctl start shellinabox

sudo apt-get install -y mariadb-server
sudo mysql << EOF
USE mysql;
UPDATE user SET password=password('root') WHERE user='root';
UPDATE user SET plugin='mysql_native_password' WHERE user='root';
CREATE DATABASE IF NOT EXISTS hallelujah CHARSET utf8 COLLATE utf8_bin;
FLUSH PRIVILEGES;
EXIT;
EOF

sudo apt-get install -y shadowsocks-qt5
sudo cat > ~/proxy.sh <<EOF
export http_proxy="socks5://127.0.0.1:1080"
export https_proxy="socks5://127.0.0.1:1080"
export no_proxy="localhost, 127.0.0.1, 192.168.*"
EOF
chmod u+x ~/proxy.sh
echo "alias chrome='nohup chromium-browser --proxy-server=\"socks5://127.0.0.1:1080\" > /dev/null 2>&1 &'" >> ~/.bashrc
