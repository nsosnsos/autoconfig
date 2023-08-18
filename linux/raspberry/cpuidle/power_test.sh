#!/usr/bin/env bash
#set -x
set -e

CUR_USER=$(whoami)
HOME_PATH=$(eval echo ~${CUR_USER})
SCRIPT_PATH=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
SCRIPT_NAME=$(basename $(readlink -f "${0}"))


function usage() {
	echo "Usage: ${SCRIPT_NAME}"
	echo "       This is linux power test script for raspberry 4b model building linux kernel."
}

# set source path
WORK_PATH=${HOME_PATH}/Workspace
LINUX_PATH=${WORK_PATH}/linux

# set kernel build variables
if [[ ${#} -eq 1 && ${1} -eq 32 ]]; then
    KERNEL=kernel7l
    IMAGE=zImage
    ARCH_NAME=arm
    DTS_DTB=
elif [[ ${#} -eq 0 || (${#} -eq 1 && ${1} -eq 64) ]]; then
    KERNEL=kernel8
    IMAGE=Image.gz
    ARCH_NAME=arm64
    DTS_DTB="broadcom/"
else
	usage
	exit -1
fi

# start time
START_TIME=$(date +%s)

# clone source
sudo apt install git bc bison flex libssl-dev make libncurses5-dev -y
if [[ ! -d "${LINUX_PATH}" ]]; then
	echo "downloading linux source ..."
	git clone --depth=1 https://github.com/raspberrypi/linux ${LINUX_PATH}
fi

# kernel config for raspberry 4b model
cd ${LINUX_PATH}
make bcm2711_defconfig
KERNEL_VERSION="test"
sed -i "s|CONFIG_LOCALVERSION=\"[^\"]*\"|CONFIG_LOCALVERSION=\"${KERNEL_VERSION}\"|g" .config

# compile linux kernel
make -j$(nproc) ${IMAGE} modules dtbs
sudo make modules_install

# end time
END_TIME=$(date +%s)
echo "Elapsed Time: $((${END_TIME} - ${START_TIME})) seconds."

