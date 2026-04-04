#!/usr/bin/env bash
set -e

SCRIPT_PATH=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source ${SCRIPT_PATH}/../linux/logging.sh

log_info "Installing dependencies..."
log_exec "sudo apt install -y automake autoconf libcurl4-openssl-dev"

WORKSPACE=~/Workspace
if [ ! -d "$WORKSPACE" ]; then
    log_info "Creating workspace directory: $WORKSPACE"
    mkdir -p "$WORKSPACE"
fi

cd "$WORKSPACE"

if [ -d "cpuminer" ]; then
    log_warn "cpuminer directory already exists, removing..."
    rm -rf cpuminer
fi

log_info "Cloning cpuminer repository..."
log_exec "git clone https://github.com/pooler/cpuminer.git"

cd cpuminer

log_info "Running autogen..."
log_exec "./autogen.sh"

log_info "Configuring build..."
log_exec "./configure CFLAGS=\"-O3\""

log_info "Building and installing..."
log_exec "sudo make"
log_exec "sudo make install"

#./minerd --url=stratum+tcp://stratum.slushpool.com:3333 --userpass=nsos.worker1:password

log_info "Creating systemd service..."
sudo cat > /etc/systemd/system/miner.service <<EOF
[Unit]
Description=BitCoin Mining Service
After=syslog.target network.target auditd.service

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/minerd --url=stratum+tcp://stratum.slushpool.com:3333 --userpass=nsos.worker1:password -t 1
ExecReload=/bin/kill -HUP \$MAINPID
ExecStop=/bin/kill -s QUIT \$MAINPID
PrivateTmp=true
Restart=always
RestartSec=120s

[Install]
WantedBy=multi-user.target
EOF

log_info "Enabling and starting miner service..."
log_exec "sudo systemctl daemon-reload"
log_exec "sudo systemctl enable miner"
log_exec "sudo systemctl restart miner"
log_exec "sudo systemctl status miner"

log_info "Bitcoin miner installation completed successfully"

