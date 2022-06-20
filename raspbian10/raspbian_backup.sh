#!/usr/bin/env bash
set -e
set -x

echo "==================== STAGE 1 ===================="
sudo apt-get -y install rsync dosfstools parted kpartx exfat-fuse

backup_dir=/mnt
if [ "$#" -lt 1 ]; then
	echo "We need portable device for backup, is it /dev/sda ? Y/N"
	read answer
	if [ "$answer" = "y" -o "$answer" = "Y" ]; then
		sudo mount -o uid=1000 /dev/sda $backup_dir
	else
		echo "Usage: $0 /dev/sda (check with \"fdisk -l\")"
		exit 0
	fi
else
	sudo mount -o uid=1000 $1 $backup_dir
fi

if [ -z "`grep $backup_dir /etc/mtab`" ]; then
	echo "Failed to mount portable device, exit backup!"
	exit 0
fi
echo "Portable device is mounted for backup task."

echo "==================== STAGE 2 ===================="
backup_img=$backup_dir/raspbian_`date +%Y%m%d%H%M%S`.img
boot_size=`df -P | grep /boot | awk '{print $2}'`
root_size=`df -P | grep /dev/root | awk '{print $3}'`
total_size=`echo $boot_size $root_size | awk '{print int(($1+$2)*1.3/1024)}'`
sudo dd if=/dev/zero of=$backup_img bs=1M count=$total_size

boot_start=`sudo fdisk -l /dev/mmcblk0 | grep mmcblk0p1 | awk '{print $2}'`
boot_end=`sudo fdisk -l /dev/mmcblk0 | grep mmcblk0p1 | awk '{print $3}'`
root_start=`sudo fdisk -l /dev/mmcblk0 | grep mmcblk0p2 | awk '{print $2}'`
root_end=`sudo fdisk -l /dev/mmcblk0 | grep mmcblk0p2 | awk '{print $3}'`
echo "/boot:[$boot_start - $boot_end]  root:[$root_start : $root_end]"

sudo parted $backup_img --script -- mklabel msdos
sudo parted $backup_img --script -- mkpart primary fat32 ${boot_start}s ${boot_end}s
sudo parted $backup_img --script -- mkpart primary ext4 ${root_start}s -1
sleep 5
loop_device=`sudo losetup -f --show $backup_img`
sleep 5
device=/dev/mapper/`sudo kpartx -va $loop_device | sed -E 's/.*(loop[0-9])p.*/\1/g' | head -1`
sleep 5
sudo mkfs.vfat ${device}p1 -n boot
sudo mkfs.ext4 ${device}p2
echo "Partition is done for backup image."

echo "==================== STAGE 3 ===================="
mount_boot=$backup_dir/backup_boot/
mount_root=$backup_dir/backup_root/
sudo mkdir -p $mount_boot $mount_root

sudo mount -t vfat ${device}p1 $mount_boot

sudo cp -rfp /boot/* $mount_boot
sync
echo "$mount_boot is done."

echo "==================== STAGE 4 ===================="
sudo mount -t ext4 ${device}p2 $mount_root

if [ -f /etc/dphys-swapfile ]; then
        SWAPFILE=`cat /etc/dphys-swapfile | grep ^CONF_SWAPFILE | cut -f 2 -d=`
	if [ "$SWAPFILE" = "" ]; then
		SWAPFILE=/var/swap
	fi
	EXCLUDE_SWAPFILE="--exclude $SWAPFILE"
fi

sudo rsync --force -rltWDEHXAgoptx --delete --stats --progress \
	$EXCLUDE_SWAPFILE \
	--exclude '.gvfs' \
	--exclude '/dev' \
    --exclude '/media' \
	--exclude '/mnt' \
	--exclude '/proc' \
    --exclude '/run' \
	--exclude '/sys' \
	--exclude '/tmp' \
    --exclude 'lost\+found' \
	--exclude '$backup_dir' \
	/ $mount_root

for i in dev media mnt proc run sys boot; do
	if [ ! -d $mount_root/$i ]; then
		sudo mkdir $mount_root/$i
	fi
done

if [ ! -d $mount_root/tmp ]; then
	sudo mkdir $mount_root/tmp
	sudo chmod a+w $mount_root/tmp
fi

sync
echo "$mount_root is done."

echo "==================== STAGE 5 ===================="
origin_partition_uuid_boot=`sudo blkid -o export /dev/mmcblk0p1 | grep PARTUUID`
origin_partition_uuid_root=`sudo blkid -o export /dev/mmcblk0p2 | grep PARTUUID`
backup_partition_uuid_boot=`sudo blkid -o export ${device}p1 | grep PARTUUID`
backup_partition_uuid_root=`sudo blkid -o export ${device}p2 | grep PARTUUID`
sudo sed -i "s/$origin_partition_uuid_root/$backup_partition_uuid_root/g" $mount_boot/cmdline.txt
sudo sed -i "s/$origin_partition_uuid_boot/$backup_partition_uuid_boot/g" $mount_root/etc/fstab
sudo sed -i "s/$origin_partition_uuid_root/$backup_partition_uuid_root/g" $mount_root/etc/fstab
echo "Uuid of image partitions are modified."

echo "==================== STAGE 6 ===================="
sudo umount $mount_boot
sudo umount $mount_root

sudo kpartx -d $loop_device
sudo losetup -d $loop_device
sudo umount $backup_dir
rm -rf $mount_boot $mount_root
echo "$backup_img is generated!\nRaspbian backup task is done!"

