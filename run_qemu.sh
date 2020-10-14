#!/bin/bash

RASPBIAN=2017-04-10-raspbian-jessie
set -x

function error_check {
	test $? -eq 0 || { echo "the last command failed"; exit 1; }
}
command -v qemu-system-arm >/dev/null 2>&1 || { echo >&2 "Please install qemu-system-arm.  Aborting."; exit 1; }

# ensure we are running as sudo
if [ "$EUID" -ne 0 ]
  then echo "Please run as sudo"
  exit
fi

# create a workspace
if [ ! -d ~/qemu_vms ]; then 
	mkdir ~/qemu_vms/
	error_check
fi

pushd ~/qemu_vms

# pull down a raspbian image
#wget http://downloads.raspberrypi.org/raspbian/images/raspbian-2017-04-10/${RASPBIAN}.zip
error_check

# get the latest RPi kerenl for qemu
#git clone https://github.com/dhruvvyas90/qemu-rpi-kernel.git
error_check

#unzip ${RASPBIAN}.zip
error_check
fdisk -l ${RASPBIAN}.img
error_check
BOOT_START=$(fdisk -l ${RASPBIAN}.img | awk -v pat="${RASPBIAN}.img2" '$0 ~ pat {print $2}')
error_check
MOUNT_OFFSET=$(($BOOT_START * 512))

# mount the image for use with qemu
if [ ! -d /mnt/raspbian ]; then
	mkdir /mnt/raspbian
	error_check
fi
mount -v -o offset=$MOUNT_OFFSET -t ext4 ~/qemu_vms/${RASPBIAN}.img /mnt/raspbian
error_check

# configure files
sed -i 's/^/# /' /mnt/raspbian/etc/ld.so.preload
error_check
sed -i 's/mmcblk0p1/sda1/' /mnt/raspbian/etc/fstab
error_check
sed -i 's/mmcblk0p2/sda2/' /mnt/raspbian/etc/fstab
error_check
umount /mnt/raspbian
error_check
popd

cd ~
error_check

qemu-system-arm -kernel ~/qemu_vms/qemu-rpi-kernel/kernel-qemu-4.4.34-jessie -cpu arm1176 -m 256 -M versatilepb -serial stdio -append "root=/dev/sda2 rootfstype=ext4 rw" -hda ~/qemu_vms/${RASPBIAN}.img -redir tcp:5022::22 -no-reboot
