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
	echo "       If it is not specified, it would be a 32-bit build configuration."
}

# set source path
WORK_PATH=${HOME_PATH}/Workspace
LINUX_PATH=${WORK_PATH}/linux

# clone source
sudo apt install git bc bison flex libssl-dev make -y
if [[ ! -d "${LINUX_PATH}" ]]; then
	echo "downloading linux source ..."
	git clone --depth=1 https://github.com/raspberrypi/linux ${LINUX_PATH}
fi
exit 0

# kernel config for raspberry 4b model
cd ${LINUX_PATH}
if [[ ${#} -eq 1 && ${1} -eq 64 ]]; then
	KERNEL=kernel8
elif [[ ${#} -eq 0 || (${#} -eq 1 && ${1} -eq 32) ]]; then
	KERNEL=kernel7l
else
	usage
	exit -1
fi
make bcm2711_defconfig

# customize kernel version
read -p "Enter kernel version: " KERNEL_VERSION
sed -i "s|CONFIG_LOCALVERSION=\"$(uname -r)\"|CONFIG_LOCALVERSION=\"${KERNEL_VERSION}\"|g" .config

# compile linux kernel
NUM_CPUS=$(cat /proc/cpuinfo | grep "processor" | wc -l)
if [[ ${KERNEL} == "kernel8" ]]; then
	make -j${NUM_CPUS} zImage modules dtbs
	sudo make modules_install
	sudo cp arch/arm/boot/dts/*.dtb /boot/
	sudo cp arch/arm/boot/dts/overlays/*.dtb* /boot/overlays/
	sudo cp arch/arm/boot/dts/overlays/README /boot/overlays/
	sudo cp arch/arm/boot/zImage /boot/${KERNEL_VERSION}.img
else
	make -j${NUM_CPUS} Image.gz modules dtbs
	sudo make modules_install
	sudo cp arch/arm64/boot/dts/broadcom/*.dtb /boot/
	sudo cp arch/arm64/boot/dts/overlays/*.dtb* /boot/overlays/
	sudo cp arch/arm64/boot/dts/overlays/README /boot/overlays/
	sudo cp arch/arm64/boot/Image.gz /boot/${KERNEL_VERSION}.img
fi

