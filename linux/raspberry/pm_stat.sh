#!/usr/bin/env bash
#set -x
set -e


CUR_USER=$(whoami)
HOME_PATH=$(eval echo ~${CUR_USER})
SCRIPT_PATH=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SCRIPT_NAME=$(basename $(readlink -f "${0}"))

WORK_PATH=${HOME_PATH}/Workspace

# get throttled
echo "throttle status:"
vcgencmd get_throttled
# cpu clock monitor
echo "cpu clock:"
vcgencmd measure_clock arm
# gpu clock monitor
echo "gpu clock:"
vcgencmd measure_clock core
# voltage monitor
echo "voltage:"
vcgencmd measure_volts
# temperature monitor
echo "system temperature:"
vcgencmd measure_temp
echo "pmic temperature:"
vcgencmd measure_temp pmic

