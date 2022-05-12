#!/usr/bin/env bash

set -e
set -x

config_file=/home/ubuntu/shadowsocks.conf
service_file=/etc/systemd/system/shadowsocks.service

sudo apt-get update && sudo apt-get upgrade -y
sudo pip3 install --upgrade pip
sudo rm -rf /usr/bin/pip3
sudo ln -s /usr/local/bin/pip3.6 /usr/bin/pip3
sudo pip3 install shadowsocks

sudo sed -i "s/EVP_CIPHER_CTX_cleanup/EVE_CIPHER_CTX_reset/g" /usr/local/lib/python3.6/dist-packages/shadowsocks/crypto/openssl.py

cat > ${config_file} <<EOF
{
	"server":"0.0.0.0",
	"server_port":443,
	"local_address":"127.0.0.1",
	"local_port":1080,
	"password":"1234567",
	"timeout":300,
	"method":"aes-256-cfb",
	"fast_open":false,
	"workers":1
}
EOF

sudo touch ${service_file}
sudo chmod 666 ${service_file}
sudo cat > ${service_file} <<EOF
[Unit]
Description=Shadowsocks Service
After=network.target

[Service]
ExecStart=/usr/local/bin/ssserver -c ${config_file}
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOF
sudo chmod 644 ${service_file}

sudo systemctl daemon-reload
sudo systemctl enable shadowsocks
sudo systemctl start shadowsocks
