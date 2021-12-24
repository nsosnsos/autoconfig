#!/bin/bash

sudo apt-get install automake autoconf libcurl4-openssl-dev
cd ~/Workspace
git clone https://github.com/pooler/cpuminer.git
cd cpuminer
 ./autogen.sh
./configure CFLAGS="-O3"
sudo make & sudo make install

#./minerd --url=stratum+tcp://stratum.slushpool.com:3333 --userpass=nsos.worker1:password

sudo cat > /etc/systemd/system/miner.service <<EOF
[Unit]
Description=BitCoin Mining Service
After=syslog.target network.target auditd.service

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/minerd --url=stratum+tcp://stratum.slushpool.com:3333 --userpass=nsos.worker1:password -t 1
ExecReload=/bin/kill -HUP $MAINPID
ExecStop=/bin/kill -s QUIT $MAINPID
PrivateTmp=true
Restart=always
RestartSec=120s

[Install]
WantedBy=multi-user.target
EOF

systemctl enable miner
systemctl restart miner
systemcrl status miner
