#!/usr/bin/env bash
#set -x
set -e

CUR_USER=$(whoami)
HOME_PATH=$(eval echo ~${CUR_USER})
SCRIPT_PATH=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
SCRIPT_NAME=$(basename $(readlink -f "${0}"))


function usage() {
	echo "Usage: ${SCRIPT_NAME} [32|64]"
	echo "       This is linux kernel build script for raspberry 4b model."
	echo "       You may specify 32-bit or 64-bit build configuration for linux kernel."
	echo "       If it is not specified, it would be a 64-bit build configuration."
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

# clone source
sudo apt install git bc bison flex libssl-dev make libncurses5-dev -y
if [[ ! -d "${LINUX_PATH}" ]]; then
	echo "downloading linux source ..."
	git clone --depth=1 https://github.com/raspberrypi/linux ${LINUX_PATH}
fi

# kernel config for raspberry 4b model
cd ${LINUX_PATH}
make bcm2711_defconfig
read -p "Enter kernel version: " KERNEL_VERSION
sed -i "s|CONFIG_LOCALVERSION=\"[^\"]*\"|CONFIG_LOCALVERSION=\"${KERNEL_VERSION}\"|g" .config

# compile linux kernel
make -j$(nproc) ${IMAGE} modules dtbs
sudo make modules_install
sudo cp arch/${ARCH_NAME}/boot/dts/${DTS_DTB}*.dtb /boot/
sudo cp arch/${ARCH_NAME}/boot/dts/overlays/*.dtb* /boot/overlays/
sudo cp arch/${ARCH_NAME}/boot/dts/overlays/README /boot/overlays/
sudo cp arch/${ARCH_NAME}/boot/${IMAGE} /boot/${KERNEL_VERSION}.img

# change boot kernel
if ! grep -Fq "kernel=" /boot/config.txt; then
    echo "kernel=${KERNEL_VERSION}.img" | sudo tee -a /boot/config.txt
else
    sudo sed -i "s|kernel=.*\.img|kernel=${KERNEL_VERSION}.img|g" /boot/config.txt
fi
echo "New kernel ${KERNEL_VERSION} is ready, please check /boot/${KERNEL_VERSION}.img and /boot/config.txt"
echo "You may reboot to run new kernel."

