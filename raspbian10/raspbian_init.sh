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

# Install v2ray and v2raya
curl -Ls https://mirrors.v2raya.org/go.sh | sudo bash
sudo systemctl disable v2ray --now
wget -qO - https://apt.v2raya.org/key/public-key.asc | sudo tee /etc/apt/trusted.gpg.d/v2raya.asc
echo "deb https://apt.v2raya.org/ v2raya main" | sudo tee /etc/apt/sources.list.d/v2raya.list
sudo apt update
sudo apt install v2raya
sudo systemctl enable v2raya.service
sudo systemctl start v2raya.service

# Set system proxy
sudo cat > ~/proxy.sh <<EOF
export http_proxy="socks5://127.0.0.1:20170"
export https_proxy="socks5://127.0.0.1:20170"
export no_proxy="localhost, 127.0.0.1, 192.168.*"
EOF
chmod u+x ~/proxy.sh
echo "alias chrome='nohup chromium-browser --proxy-server=\"socks5://127.0.0.1:20170\" > /dev/null 2>&1 &'" >> ~/.bashrc

