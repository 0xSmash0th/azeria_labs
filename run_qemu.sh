#!/bin/bash

RASPBIAN=2017-04-10-raspbian-jessie
set -x

qemu_tap_cmd='sudo qemu-system-arm -kernel ~/qemu_vms/qemu-rpi-kernel/kernel-qemu-4.4.34-jessie -cpu arm1176 -m 256 -M versatilepb -serial stdio -append "root=/dev/sda2 rootfstype=ext4 rw" -hda ~/qemu_vms/${RASPBIAN}.img -net nic -net tap,ifname=tap0,script=no,downscript=no -no-reboot'
qemu_ssh_cmd='qemu-system-arm -kernel ~/qemu_vms/qemu-rpi-kernel/kernel-qemu-4.4.34-jessie -cpu arm1176 -m 256 -M versatilepb -serial stdio -append "root=/dev/sda2 rootfstype=ext4 rw" -hda ~/qemu_vms/${RASPBIAN}.img -redir tcp:5022::22 -no-reboot'

function error_check {
	test $? -eq 0 || { echo "the last command failed"; exit 1; }
}

#check that we have qemu
command -v qemu-system-arm >/dev/null 2>&1 || { echo >&2 "Please install qemu-system-arm.  Aborting."; exit 1; }
command -v tunctl >/dev/null 2>&1 || { echo >&2 "Please install uml-utilities.  Aborting."; exit 1; }

if [ $1 = "setup" ]; then 
	
	# create a workspace
	if [ ! -d ~/qemu_vms ]; then 
		mkdir ~/qemu_vms/
		error_check
	fi
	
	pushd ~/qemu_vms
	
	# pull down a raspbian image
	wget http://downloads.raspberrypi.org/raspbian/images/raspbian-2017-04-10/${RASPBIAN}.zip
	error_check
	
	# get the latest RPi kerenl for qemu
	git clone https://github.com/dhruvvyas90/qemu-rpi-kernel.git
	error_check
	
	unzip ${RASPBIAN}.zip
	error_check
	BOOT_START=$(fdisk -l ${RASPBIAN}.img | awk -v pat="${RASPBIAN}.img2" '$0 ~ pat {print $2}')
	error_check
	MOUNT_OFFSET=$(($BOOT_START * 512))
	
	# mount the image for use with qemu
	if [ ! -d /mnt/raspbian ]; then
		sudo mkdir /mnt/raspbian
		error_check
	fi
	sudo mount -v -o offset=$MOUNT_OFFSET -t ext4 ~/qemu_vms/${RASPBIAN}.img /mnt/raspbian
	error_check
	
	# configure files
	sudo sed -i 's/^/# /' /mnt/raspbian/etc/ld.so.preload
	error_check
	sudo sed -i 's/mmcblk0p1/sda1/' /mnt/raspbian/etc/fstab
	error_check
	sudo sed -i 's/mmcblk0p2/sda2/' /mnt/raspbian/etc/fstab
	error_check
	sudo umount /mnt/raspbian
	error_check
	popd
	
	cd ~
	error_check

	# setup networking
	sudo tunctl -t tap0 -u azeria
	sudo ifconfig tap0 172.16.0.1/24

	echo "########################################################\n\tRUN THE FOLLOWING COMMANDS IN THE RASPBIAN TERMINAL:\n\tsudo service ssh start\n\tsudo update-rc.d ssh enable\n\nYou should now be able to ssh to your qemu raspbian with: ssh pi@127.0.0.1 -p 5022\nThe default password is raspberry\n\nSee: https://azeria-labs.com/emulate-raspberry-pi-with-qemu/ for Advanced setup and trouble-shooting\n\n"
	
	eval $qemu_ssh_cmd
	
else
	# setup ssh on port 5022 unless the tap cmd is present 
	if [ $1 = "tap" ]; then
		eval $qemu_tap_cmd
	else
		eval $qemu_ssh_cmd
	fi
fi
