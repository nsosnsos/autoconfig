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

sudo apt-get install xrdp
sudo apt-get install ntpdate
sudo ntpdate -u ntp.ubuntu.com

sudo apt-get install ttf-wqy-zenhei ttf-wqy-microhei xfonts-wqy
sudo apt-get install fcitx fcitx-googlepinyin fcitx-module-cloudpinyin fcitx-sunpinyin

sudo apt-get install vim vim-scripts vim-doc vim-addon-manager
sudo apt-get install ctags cscope tree
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

sudo apt-get install python3-pip
# sudo pip3 install --upgrade pip
# curl https://files.pythonhosted.org/packages/ce/ea/9b445176a65ae4ba22dce1d93e4b5fe182f953df71a145f557cffaffc1bf/pip-19.3.1.tar.gz
# tar -zxvf pip-19.3.1.tar.gz
# cd pip-19.3.1 && python3 setup.py install
# cd ~ && sudo rm -rf ~/Downloads/pip-19.3.1
# rm -rf /usr/bin/pip3
# ln -s /usr/local/bin/pip3 /usr/bin/pip3

sudo apt-get install python3-dev libxml2-dev libxslt1-dev zlib1g-dev libhdf5-dev libblas-dev liblapack-dev libatlas-base-dev gfortran
sudo pip3 install wrapt --ignore-installed
sudo pip3 install pandas numpy scipy tensorflow matplotlib

ssh-keygen -t rsa -d 4096 -C "nsosnsos@gmail.com"
cp ~/.ssh/id_rsa.pub ~/.ssh/authorized_keys
