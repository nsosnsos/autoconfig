#!/usr/bin/env bash
set -x

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

sudo bash v2ray_install.sh
sudo bash v2ray_dat_install.sh

sudo cp v2ray_config.json /usr/local/etc/v2ray/config.json
sudo systemctl restart v2ray

