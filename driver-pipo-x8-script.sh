#!/bin/bash
# This script fetch, compile, install and configure additional drivers
# needed by Pipo X8 with Debian 8 installed. Main reference to this
# work could be found on https://wiki.debian.org/InstallingDebianOn/PIPO/PIPO%20X8

# Global variables
ORIG_DIR="$(pwd)"

function _configure_repos() {
	# Backports for Jessie, needed for newer kernel
	echo "deb http://ftp.es.debian.org/debian/ jessie-backports main" > /etc/apt/sources.list.d/jessie-backports.list
	apt update
}


function _install_packages() {
	PACKAGES="$@"
	apt install -y $PACKAGES
}

# Touchscreen, free driver
function _touchscreen() {
	KERNEL_TARGET="4.6.0-0.bpo.1-amd64"
	# Check if needed packages are installed
	_configure_repos
	_install_packages build-essential linux-image-$KERNEL_TARGET/jessie-backports linux-headers-$KERNEL_TARGET/jessie-backports  linux-base/jessie-backports

	# This module has to be compiled and patched	
	cd /usr/src
	mkdir driver-touchscreen
	cd driver-touchscreen
	wget "http://git.kernel.org/cgit/linux/kernel/git/torvalds/linux.git/plain/drivers/input/touchscreen/goodix.c"

	wget "https://raw.githubusercontent.com/Librerouter/Librekernel/gh-pages/driver-pipo-x8-script-files/0001-Input-goodix-add-changes-to-support-PIPO-X8.patch"
	cat 0001-Input-goodix-add-changes-to-support-PIPO-X8.patch | patch

	echo -e "obj-m += goodix.o\nall:\n\tmake -C /lib/modules/$KERNEL_TARGET/build M=\$(PWD) modules\nclean:\n\tmake -C /lib/modules/$KERNEL_TARGET/build M=\$(PWD) clean" > Makefile
	make
	#echo -n 'file gpiolib.c +p' > /sys/kernel/debug/dynamic_debug/control
	#echo -n 'file gpiolib-acpi.c +p' > /sys/kernel/debug/dynamic_debug/control
	#echo -n 'file property.c +p' > /sys/kernel/debug/dynamic_debug/control
	# Moving compiled module to proper path
	cp goodix.ko /lib/modules/${KERNEL_TARGET}/kernel/drivers/input/touchscreen/
	# Running depmod to refresh modules dependency 
	depmod $KERNEL_TARGET
	echo goodix >> /etc/modules
	echo "###### YOU MUST RESTART AND SELECT $KERNEL_TARGET ######"
}

# Internal Wireless NIC, non-free driver
function _wireless_internal() {
	echo do nothing
}

# Install just free drivers
function _free_drivers() {
	_touchscreen
}

function _non-free_drivers() {
	_wireless_internal
}

case $1 in
	free)
		_free_drivers
	;;

	non-free)
		_non-free_drivers
	;;
	
	all)
		_free_drivers
		_non-free_drivers

	;;

	*)
		echo "Usage:"
		echo " $0 free : Install just free drivers"
		echo " $0 non-free : Install just non-free drivers"
		echo " $0 all : Install free and non-free drivers"
	;;
esac
