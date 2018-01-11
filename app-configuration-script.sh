#!/bin/bash
# ---------------------------------------------------------
# This script aims to configure all the packages and 
# services which have been installed by test.sh script.
# This script is functionally seperated into 4 parts
#       1. Detect system variables
# 	2. Configuration of Network Interfaces 
# 	3. Configuration of Revers Proxy Services 
# 	4. Configuration of Applications
# ---------------------------------------------------------


# ---------------------------------------------------------
# Variables list
# ---------------------------------------------------------
PROCESSOR="Not Detected"        # Processor type (ARM/Intel/AMD)
HARDWARE="Not Detected"         # Hardware type (Board/Physical/Virtual)
PLATFORM="Not Detected"         # Platform type (U12/U14/D7/D8/T7)
ARCH="Not Detected"		# Architecture (i386/x86_64)
EXT_INTERFACE="Not Detected"    # External Interface (Connected to Internet)
INT_INETRFACE="Not Detected"    # Internal Interface (Connected to local network)
POSTFIX_PASS="null"		# Password for postfixadmin admin account

# ---------------------------------------------------------
# This function checks user. 
# Script must be executed by root user, otherwise it will
# output an error and terminate further execution.
# ---------------------------------------------------------
check_root ()
{
	echo -ne "Checking user root ... " | tee /var/libre_config.log
	if [ "$(whoami)" != "root" ]; then
		echo "Fail"
		echo "You need to be root to proceed. Exiting"
		exit 1
	else
	echo "OK" | tee -a /var/libre_config.log
fi
}


# ---------------------------------------------------------
# Function to get varibales from /var/box_variables file
# Variables to be initialized are:
#   PLATFORM
#   HARDWARE
#   PROCESSOR
#   EXT_INTERFACE
#   INT_INTERFACE
# ----------------------------------------------------------
get_variables()
{
	echo "Initializing variables ..." | tee -a /var/libre_config.log
	if [ -e /var/box_variables ]; then
		PLATFORM=`cat /var/box_variables | grep "Platform" | awk {'print $2'}`
		HARDWARE=`cat /var/box_variables | grep "Hardware" | awk {'print $2'}`
		PROCESSOR=`cat /var/box_variables | grep "Processor" | awk {'print $2'}`
		ARCH=`cat /var/box_variables | grep "Architecture" | awk {'print $2'}`
		EXT_INTERFACE=`cat /var/box_variables | grep "Ext_int" | awk {'print $2'}`
		INT_INTERFACE=`cat /var/box_variables | grep "Int_int" | awk {'print $2'}`

#	touch "/tmp/variables.log"

		if [ -z "$PLATFORM" -o -z "$HARDWARE" \
		     -o -z "$PROCESSOR" -o -z "$ARCH" \
		     -o -z "$EXT_INTERFACE" -o -z "$INT_INTERFACE" ]; then
			echo "Error: Can not detect variables. Exiting"
			exit 5
		else
			echo "Platform:      $PLATFORM" | tee -a /var/libre_config.log
			echo "Hardware:      $HARDWARE" | tee -a /var/libre_config.log
			echo "Processor:     $PROCESSOR" | tee -a /var/libre_config.log
			echo "Architecture:  $ARCH" | tee -a /var/libre_config.log
			echo "Ext Interface: $EXT_INTERFACE" | tee -a /var/libre_config.log
			echo "Int Interface: $INT_INTERFACE" | tee -a /var/libre_config.log
		fi 
	else 
		echo "Error: Can not find variables of the librerouter"  | tee -a /var/libre_config.log
		exit 6
	fi
}


# ----------------------------------------------
# This function detects platform.
#
# Suitable platform are:
#
#  * Ubuntu 12.04
#  * Ubuntu 14.04
#  * Debian GNU/Linux 7
#  * Debian GNU/Linux 8
#  * Trisquel 7
# ----------------------------------------------
get_platform ()
{
        echo "Detecting platform ..." | tee -a /var/libre_config.log
        FILE=/etc/issue
        if cat $FILE | grep "Ubuntu 12.04" > /dev/null; then
                PLATFORM="U12"
        elif cat $FILE | grep "Ubuntu 14.04" > /dev/null; then
                PLATFORM="U14"
        elif cat $FILE | grep "Debian GNU/Linux 7" > /dev/null; then
                PLATFORM="D7"
        elif cat $FILE | grep "Debian GNU/Linux 8" > /dev/null; then
                PLATFORM="D8"
        elif cat $FILE | grep "Trisquel GNU/Linux 7.0" > /dev/null; then
                PLATFORM="T7"
        else
                echo "ERROR: UNKNOWN PLATFORM" | tee -a /var/libre_config.log
                exit
        fi
        echo "Platform: $PLATFORM" | tee -a /var/libre_config.log
}


# ----------------------------------------------
# This function checks hardware
# Hardware can be.
# 1. Intel board pipo x10.
# 2. Intel Physical/Virtual machine.
# Function gets Processor, Hardware and
# Architecture types and saves them in 
# PROCESSOR, HARDWARE and ARCH variables.
# ----------------------------------------------
get_hardware()
{
         echo "Detecting hardware ..." | tee -a /var/libre_config.log

        # Checking CPU for ARM and saving
        # Processor and Hardware types in
        # PROCESSOR and HARDWARE variables
        if grep ARM /proc/cpuinfo > /dev/null 2>&1; then
           PROCESSOR="ARM"
           HARDWARE=`cat /proc/cpuinfo | grep Hardware | awk {'print $3'}`
        # Checking CPU for Intel and saving
        # Processor and Hardware types in
        # PROCESSOR and HARDWARE variables
        elif grep Intel /proc/cpuinfo > /dev/null 2>&1;  then
           PROCESSOR="Intel"
           HARDWARE=`dmidecode -s system-product-name`
        # Checking CPU for AMD and saving
        # Processor and Hardware types in
        # PROCESSOR and HARDWARE variables
        elif grep AMD /proc/cpuinfo > /dev/null 2>&1;  then
           PROCESSOR="AMD"
           HARDWARE=`dmidecode -s system-product-name`
        fi

        # Detecting Architecture
        ARCH=`uname -m`

        # Printing Processor Hardware and Architecture types

        echo "Processor: $PROCESSOR" | tee -a /var/libre_config.log
        echo "Hardware: $HARDWARE" | tee -a /var/libre_config.log
        echo "Architecture: $ARCH" | tee -a /var/libre_config.log
}


# ----------------------------------------------
# This function enables DHCP client and checks
# for Internet on predefined network interface.
#
# Steps to define interface are:
#
# 1. Checking Internet access.
# *
# *
# ***** If success.
# *
# *     2. Get Interface name
# *
# ***** If no success.
#     *
#     * 2. Checking for DHCP server and Internet in
#       *  network connected to eth0.
#       *
#       ***** If success.
#       *   *
#       *   * 2. Enable DHCP client on eth0 and
#       *        default route to eth0
#       *
#       ***** If no success.
#           *
#           * 2. Checking for DHCP server and Internet
#           *  in network connected to eth1
#           *
#           ***** If success.
#           *   *
#           *   * 3. Enable DHCP client on eth1.
#           *
#           *
#           ***** If no success.
#               *
#               * 3. Warn user and exit with error.
#
# ----------------------------------------------
get_interfaces()
{
	# Removing firewall
	iptables -F
	iptables -t nat -F
	iptables -t mangle -F	

        # Check internet Connection. If Connection exist then get
        # and save Internet side network interface name in
        # EXT_INTERFACE variable
        if ping -c1 8.8.8.8 >/dev/null 2>/dev/null; then
                EXT_INTERFACE=`route -n | awk {'print $1 " " $8'} | grep "0.0.0.0" | awk {'print $2'} | sed -n '1p'`
                echo "Internet connection established on interface $EXT_INTERFACE" | tee -a /var/libre_config.log
        else
                # Checking eth0 for Internet connection
                echo "Getting Internet access on eth0" 
                echo "# interfaces(5) file used by ifup(8) and ifdown(8) " > /etc/network/interfaces
                echo -e "auto lo\niface lo inet loopback\n" >> /etc/network/interfaces
                echo -e  "auto eth0\niface eth0 inet dhcp" >> /etc/network/interfaces
                /etc/init.d/networking restart
                if ping -c1 8.8.8.8 >/dev/null 2>/dev/null; then
                        echo "Internet conection established on: eth0"
                        EXT_INTERFACE="eth0"
                else
                        echo "Warning: Unable to get Internet access on eth0"
                        # Checking eth1 for Internet connection
                        echo "Getting Internet access on eth1"
                        echo "# interfaces(5) file used by ifup(8) and ifdown(8) " > /etc/network/interfaces
                        echo -e "auto lo\niface lo inet loopback\n" >> /etc/network/interfaces
                        echo -e "auto eth1\niface eth1 inet dhcp" >> /etc/network/interfaces
                        /etc/init.d/networking restart
                        if ping -c1 8.8.8.8 >/dev/null 2>/dev/null; then
                                echo "Internet conection established on: eth1"
                                EXT_INTERFACE="eth1"
                        else
                                echo "Warning: Unable to get Internet access on eth1"
                                echo "Please plugin Internet cable to eth0 or eth1 and enable DHCP on gateway"
                                echo "Error: Unable to get Internet access. Exiting"
                                exit 7
                        fi
                fi
        fi
			echo "Checking DNS resolution ..." | tee -a /var/libre_config.log
                        if ! getent hosts github.com >> /var/libre_config.log; then
                        echo "You need DNS resolution to proceed... Exiting" | tee -a /var/libre_config.log
                        exit 1
                        fi
                        echo "Showing the interface configuration ..." | tee -a /var/libre_config.log
                        CLINKUP=$(ip link |grep UP |grep eth | cut -d: -f2 |sed -n 1p)
                        CWANIP=$(wget -qO- ipinfo.io/ip)
                        CLANIP=$(ifconfig $CLINKUP | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')
                        CNETMASK=$(ifconfig $CLINKUP | grep 'Mask:' | cut -d: -f4 | awk '{ print $1}')
                        CGWIP=$(route -n | grep 'UG[ \t]' | awk '{print $2}')
                        CDNS=$(cat /etc/resolv.conf | cut -d: -f2 | awk '{ print $2}')
			echo 'Wired interface:' $CLINKUP
                        echo 'Public IP:' $CWANIP
                        echo 'LAN IP:' $CLANIP
                        echo 'Netmask:' $CNETMASK
                        echo 'Gateway:' $CGWIP
                        echo 'DNS Servers:' $CDNS

        # Getting internal interface name
        # INT_INTERFACE=`ls /sys/class/net/ | grep -w 'eth0\|eth1\|wlan0\|wlan1' | grep -v "$EXT_INTERFACE" | sed -n '1p'`
	INT_INTERFACE="br1"
        echo "Internal interface: $INT_INTERFACE" | tee -a /var/libre_config.log
}


# ---------------------------------------------------------
# Function to get info about available HDDs 
# ---------------------------------------------------------
get_hdd(){
echo "Checking HDDs ..." | tee -a /var/libre_config.log

ALL_HDD=`lsblk -l | grep "disk" | awk '{print $1}' ORS=' '`
HDDS=`lsblk -l | grep "disk" | awk '{print $1}' | wc -l`

SYS_HDD=`lsblk -l | grep -w "/" | awk '{print $1}' | sed 's/[0-9]//g'`

if [ $HDDS -ge 2 ]; then
        EXT_HDD=`echo $ALL_HDD | sed s/"$SYS_HDD "//g`
else
        EXT_HDD="N/A"
fi
echo " 
Detected:  $ALL_HDD
System:    $SYS_HDD 
External:  $EXT_HDD
"  | tee -a /var/libre_config.log 
}  


# ---------------------------------------------------------
# This functions configures hostname and static lookup
# table 
# ---------------------------------------------------------
configure_hosts()
{
echo "Configuring hosts ..." | tee -a /var/libre_config.log
echo "librerouter" > /etc/hostname

cat << EOF > /etc/hosts
#
# /etc/hosts: static lookup table for host names
#

#<ip-address>   <hostname.domain.org>   <hostname>
127.0.0.1       localhost.librenet librerouter localhost
10.0.0.1        warning.librerouter.net
10.0.0.234      initial.librerouter.net
10.0.0.235      dns.librerouter.net
10.0.0.236      gui.librerouter.net
10.0.0.237      webconsole.librerouter.net
10.0.0.238      waffle.librerouter.net
10.0.0.239      snorby.librerouter.net
10.0.0.241      sogo.librerouter.net
10.0.0.242      postfix.librerouter.net
10.0.0.243      roundcube.librerouter.net
10.0.0.244      ntop.librerouter.net
10.0.0.245      webmin.librerouter.net
10.0.0.246      squidguard.librerouter.net
10.0.0.247	gitlab.librerouter.net
10.0.0.248      trac.librerouter.net
10.0.0.249      redmine.librerouter.net
10.0.0.250      conference.librerouter.net
10.0.0.251      search.librerouter.net
10.0.0.252      social.librerouter.net
10.0.0.253      storage.librerouter.net
10.0.0.254      email.librerouter.net
EOF
}


# ----------------------------------------------
# This script installs bridge-utils package and
# configures bridge interfaces.
#
# br0 = eth0 and wlan0
# br1 = eth1 and wlan1
# ----------------------------------------------
configure_bridges()
{
        EXT_BR_INT=`echo $EXT_INTERFACE | tail -c 2`
        INT_BR_INT=`echo $INT_INTERFACE | tail -c 2`

        echo "Configuring bridge interfaces..."
        echo "# interfaces(5) file used by ifup(8) and ifdown(8) " > /etc/network/interfaces
        echo "auto lo" >> /etc/network/interfaces
        echo "iface lo inet loopback" >> /etc/network/interfaces

        # Configuring bridge interfaces

        echo "#External network interface" >> /etc/network/interfaces
        echo "auto $EXT_INTERFACE" >> /etc/network/interfaces
        echo "allow-hotplug $EXT_INTERFACE" >> /etc/network/interfaces
        echo "iface $EXT_INTERFACE inet dhcp" >> /etc/network/interfaces

        echo "#External network interface" >> /etc/network/interfaces
        echo "auto wlan$EXT_BR_INT" >> /etc/network/interfaces
        echo "allow-hotplug wlan$EXT_BR_INT" >> /etc/network/interfaces
        echo "iface wlan$EXT_BR_INT inet manual" >> /etc/network/interfaces

        echo "##External Network Bridge " >> /etc/network/interfaces
        echo "#auto br$EXT_BR_INT" >> /etc/network/interfaces
        echo "#allow-hotplug br$EXT_BR_INT" >> /etc/network/interfaces
        echo "#iface br$EXT_BR_INT inet dhcp" >> /etc/network/interfaces
        echo "#bridge_ports eth$EXT_BR_INT wlan$EXT_BR_INT" >> /etc/network/interfaces

        echo "#Internal network interface" >> /etc/network/interfaces
        echo "auto $INT_INTERFACE" >> /etc/network/interfaces
        echo "allow-hotplug $INT_INTERFACE" >> /etc/network/interfaces
        echo "iface $INT_INTERFACE inet manual" >> /etc/network/interfaces

        echo "#Internal network interface" >> /etc/network/interfaces
        echo "auto wlan$INT_BR_INT" >> /etc/network/interfaces
        echo "allow-hotplug wlan$INT_BR_INT" >> /etc/network/interfaces
        echo "iface wlan$INT_BR_INT inet manual" >> /etc/network/interfaces

        echo "# Internal network Bridge" >> /etc/network/interfaces
        echo "auto br$INT_BR_INT" >> /etc/network/interfaces
        echo "allow-hotplug br$INT_BR_INT" >> /etc/network/interfaces
        echo "# Setup bridge" >> /etc/network/interfaces
        echo "iface br$INT_BR_INT inet static" >> /etc/network/interfaces
        echo "    bridge_ports eth$INT_BR_INT wlan$INT_BR_INT" >> /etc/network/interfaces
        echo "    address 10.0.0.1" >> /etc/network/interfaces
        echo "    netmask 255.255.255.0" >> /etc/network/interfaces
        echo "    network 10.0.0.0" >> /etc/network/interfaces
}


# ---------------------------------------------------------
# This function configures internal and external interfaces
# ---------------------------------------------------------
configure_interfaces()
{
	echo "Configuring Interfaces ..." | tee -a /var/libre_config.log
	# Network interfaces configuration for 
	# Physical/Virtual machine
if [ "$PROCESSOR" = "Intel" -o "$PROCESSOR" = "AMD" -o "$PROCESSOR" = "ARM" ]; then
	cat << EOF >  /etc/network/interfaces 
	# interfaces(5) file used by ifup(8) and ifdown(8)
	auto lo
	iface lo inet loopback

	#External network interface
	auto $EXT_INTERFACE
	#allow-hotplug $EXT_INTERFACE
	iface $EXT_INTERFACE inet dhcp

	#Internal network interface
	auto $INT_INTERFACE
	#allow-hotplug $INT_INTERFACE
	iface $INT_INTERFACE inet static
	bridge_ports eth1 wlan1
	    address 10.0.0.1
	    netmask 255.255.255.0
            network 10.0.0.0
    
	#Yacy
	auto $INT_INTERFACE:1
	#allow-hotplug $INT_INTERFACE:1
	iface $INT_INTERFACE:1 inet static
	    address 10.0.0.251
            netmask 255.255.255.0

	#Friendica
	auto $INT_INTERFACE:2
	#allow-hotplug $INT_INTERFACE:2
	iface $INT_INTERFACE:2 inet static
	    address 10.0.0.252
	    netmask 255.255.255.0
    
	#OwnCloud
	auto $INT_INTERFACE:3
	#allow-hotplug $INT_INTERFACE:3
	iface $INT_INTERFACE:3 inet static
	    address 10.0.0.253
	    netmask 255.255.255.0
    
	#Mailpile
	auto $INT_INTERFACE:4
	#allow-hotplug $INT_INTERFACE:4
	iface $INT_INTERFACE:4 inet static
	    address 10.0.0.254
	    netmask 255.255.255.0
	
	#Webmin
	auto $INT_INTERFACE:5
	#allow-hotplug $INT_INTERFACE:5
	iface $INT_INTERFACE:5 inet static
	    address 10.0.0.245
	    netmask 255.255.255.0
	
	#EasyRTC
	auto $INT_INTERFACE:6
	#allow-hotplug $INT_INTERFACE:6
	iface $INT_INTERFACE:6 inet static
	    address 10.0.0.250
            netmask 255.255.255.0

	#Snorby
	auto $INT_INTERFACE:7
	#allow-hotplug $INT_INTERFACE:7
	iface $INT_INTERFACE:7 inet static
	    address 10.0.0.239
	    netmask 255.255.255.0

        #squidguard
        auto $INT_INTERFACE:8
        #allow-hotplug $INT_INTERFACE:8
        iface $INT_INTERFACE:8 inet static
            address 10.0.0.246
            netmask 255.255.255.0

        #gitlab
        auto $INT_INTERFACE:9
        #allow-hotplug $INT_INTERFACE:9
        iface $INT_INTERFACE:9 inet static
            address 10.0.0.247
            netmask 255.255.255.0

        #trac
        auto $INT_INTERFACE:10
        #allow-hotplug $INT_INTERFACE:10
        iface $INT_INTERFACE:10 inet static
            address 10.0.0.248
            netmask 255.255.255.0

        #redmine
        auto $INT_INTERFACE:11
        #allow-hotplug $INT_INTERFACE:11
        iface $INT_INTERFACE:11 inet static
            address 10.0.0.249
            netmask 255.255.255.0

	#Webmin
        auto $INT_INTERFACE:12
        #allow-hotplug $INT_INTERFACE:12
        iface $INT_INTERFACE:12 inet static
            address 10.0.0.244
            netmask 255.255.255.0

        #Roundcube
        auto $INT_INTERFACE:13
        #allow-hotplug $INT_INTERFACE:13
        iface $INT_INTERFACE:13 inet static
            address 10.0.0.243
            netmask 255.255.255.0

        #Postfix
        auto $INT_INTERFACE:14
        #allow-hotplug $INT_INTERFACE:14
        iface $INT_INTERFACE:14 inet static
            address 10.0.0.242
            netmask 255.255.255.0

        #Sogo
        auto $INT_INTERFACE:15
        #allow-hotplug $INT_INTERFACE:15
        iface $INT_INTERFACE:15 inet static
            address 10.0.0.241
            netmask 255.255.255.0

        #WAF-FLE
        auto $INT_INTERFACE:17
        #allow-hotplug $INT_INTERFACE:17
        iface $INT_INTERFACE:17 inet static
            address 10.0.0.238
            netmask 255.255.255.0

        #WebConsole
        auto $INT_INTERFACE:18
        #allow-hotplug $INT_INTERFACE:18
        iface $INT_INTERFACE:18 inet static
            address 10.0.0.237
            netmask 255.255.255.0
            
        #Nxfilter
        auto $INT_INTERFACE:19
        #allow-hotplug $INT_INTERFACE:19
        iface $INT_INTERFACE:19 inet static
            address 10.0.0.2
            netmask 255.255.255.0
    
        #GUI
        auto $INT_INTERFACE:20
        #allow-hotplug $INT_INTERFACE:20
        iface $INT_INTERFACE:20 inet static
            address 10.0.0.236
            netmask 255.255.255.0

        #DNS
        auto $INT_INTERFACE:21
        #allow-hotplug $INT_INTERFACE:21
        iface $INT_INTERFACE:21 inet static
            address 10.0.0.235
            netmask 255.255.255.0

        #INITIAL
        auto $INT_INTERFACE:22
        #allow-hotplug $INT_INTERFACE:22
        iface $INT_INTERFACE:22 inet static
            address 10.0.0.234
            netmask 255.255.255.0
EOF

fi

# Restarting network configuration
/etc/init.d/networking restart
}


# ---------------------------------------------------------
# Disable reboot (CTRL + ALT + DEL)
# ---------------------------------------------------------
configure_reboot()
{
systemctl mask ctrl-alt-del.target
systemctl daemon-reload
# Disable power button
sed -i 's/^/#/' /etc/acpi/powerbtn-acpi-support.sh
}


# ---------------------------------------------------------
# Function to configure DHCP server
# ---------------------------------------------------------
configure_dhcp()
{
echo "Configuring dhcp server ..." | tee -a /var/libre_config.log
echo "
ddns-update-style none;
option domain-name \"librerouter.librenet\";
option domain-name-servers 10.0.0.2;
default-lease-time 600;
max-lease-time 7200;
authoritative;
subnet 10.0.0.0 netmask 255.255.255.0 {
range 10.0.0.100 10.0.0.200;
option routers 10.0.0.1;
}
" > /etc/dhcp/dhcpd.conf

# Configuring listen interface
sed "s~INTERFACES=\"\".*~INTERFACES=\"$INT_INTERFACE\"~g" -i /etc/default/isc-dhcp-server

# Restarting dhcp server
service isc-dhcp-server restart | tee -a /var/libre_config.log
}


# ---------------------------------------------------------
# Function to configure blacklists
# ---------------------------------------------------------
configre_blacklists()
{
#mkdir -p /etc/blacklists
#cd /etc/blacklists
#
#cat << EOF > /etc/blacklists/update-blacklists.sh
##!/bin/bash
#
##squidguard DB
#mkdir -p /etc/blacklists/shallalist/tmp 
#cd /etc/blacklists/shallalist/tmp
#wget http://www.shallalist.de/Downloads/shallalist.tar.gz
#tar xvzf shallalist.tar.gz ; res=\$?
#rm -f shallalist.tar.gz
#if [ "\$res" = 0 ]; then
# rm -fr /etc/blacklists/shallalist/ok
# mv /etc/blacklists/shallalist/tmp /etc/blacklists/shallalist/ok
#else
# rm -fr /etc/blacklists/shallalist/tmp 
#fi
#
#mkdir -p /etc/blacklists/urlblacklist/tmp
#cd /etc/blacklists/urlblacklist/tmp
#wget http://urlblacklist.com/cgi-bin/commercialdownload.pl?type=download\\&file=bigblacklist -O urlblacklist.tar.gz
#tar xvzf urlblacklist.tar.gz ; res=\$?
#rm -f urlblacklist.tar.gz
#if [ "\$res" = 0 ]; then
# rm -fr /etc/blacklists/urlblacklist/ok
# mv /etc/blacklists/urlblacklist/tmp /etc/blacklists/urlblacklist/ok
#else
# rm -fr /etc/blacklists/urlblacklist/tmp 
#fi
#
#mkdir -p /etc/blacklists/mesdk12/tmp
#cd /etc/blacklists/mesdk12/tmp
#wget http://squidguard.mesd.k12.or.us/blacklists.tgz
#tar xvzf blacklists.tgz ; res=\$?
#rm -f blacklists.tgz
#if [ "\$res" = 0 ]; then
# rm -fr /etc/blacklists/mesdk12/ok
# mv /etc/blacklists/mesdk12/tmp /etc/blacklists/mesdk12/ok
#else
# rm -fr /etc/blacklists/mesdk12/tmp 
#fi
#
#mkdir -p /etc/blacklists/capitole/tmp
#cd /etc/blacklists/capitole/tmp
#wget ftp://ftp.ut-capitole.fr/pub/reseau/cache/squidguard_contrib/publicite.tar.gz
#tar xvzf publicite.tar.gz ; res=\$?
#rm -f publicite.tar.gz
#if [ "\$res" = 0 ]; then
# rm -fr /etc/blacklists/capitole/ok
# mv /etc/blacklists/capitole/tmp /etc/blacklists/capitole/ok
#else
# rm -fr /etc/blacklists/capitole/tmp 
#fi
#
#
## chown proxy:proxy -R /etc/blacklists/*
#
#EOF
#
#chmod +x /etc/blacklists/update-blacklists.sh
#/etc/blacklists/update-blacklists.sh
#
#cat << EOF > /etc/blacklists/blacklists-iptables.sh
##ipset implementation for nat
#for i in \$(grep -iv [A-Z] /etc/blacklists/shallalist/ok/BL/adv/domains)
#do
#  iptables -t nat -I PREROUTING -i br1 -s 10.0.0.0/16 -p tcp -d \$i -j DNAT --to-destination 5.5.5.5
#done
#EOF
#
#chmod +x /etc/blacklists/blacklists-iptables.sh

cat /etc/unbound/block_domain.list.conf | awk -F '"' '{print $2}' | awk '{print $1}' > ads_domains
for i in `cat ads_domains`
do
iptables -t nat -I PREROUTING -p tcp -s 10.0.0.0/24 -d $i -j DNAT --to-destination 10.0.0.1
done

}


# ---------------------------------------------------------
# Function to configure mysql
# ---------------------------------------------------------
configure_mysql()
{
echo "Configuring MySQL ..." | tee -a /var/libre_config.log
# Getting MySQL password
if grep "DB_PASS" /var/box_variables > /dev/null 2>&1; then
	MYSQL_PASS=`cat /var/box_variables | grep "DB_PASS" | awk {'print $2'}`
else
	MYSQL_PASS=`pwgen 10 1`
	echo "DB_PASS: $MYSQL_PASS" >> /var/box_variables
	# Setting password
	mysqladmin -u root password $MYSQL_PASS | tee -a /var/libre_config.log
fi
}


# ---------------------------------------------------------
# Function to configure banks direct access to Internet
# ---------------------------------------------------------
configure_banks_access()
{
echo "Configuring banks access ..." | tee -a /var/libre_config.log
touch /var/banks_ips.txt
echo "192.229.182.219
194.224.167.58
195.21.32.34
195.21.32.40
192.229.182.219
217.148.69.165
217.148.69.240
217.148.71.165
217.148.71.240
" > /var/banks_ips.txt

touch /var/banks_access.sh
cat << EOF > /var/banks_access.sh
#!/bin/bash
for i in \$(cat /var/banks_ips.txt)
do
iptables -t nat -I PREROUTING -i $INT_INTERFACE -p tcp -d \$i -j ACCEPT
done
EOF
chmod a+x /var/banks_access.sh
}


# ---------------------------------------------------------
# Function to configure iptables
# ---------------------------------------------------------
configure_iptables()
{
echo "Configuring iptables ..." | tee -a /var/libre_config.log
# Disabling ipv6 and enabling ipv4 forwarding
echo "
net.ipv4.ip_forward=1
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
" > /etc/sysctl.conf

# Restarting sysctl
sysctl -p > /dev/null

cat << EOF > /etc/rc.local
#!/bin/sh
setterm -blank 0

iptables -X
iptables -F
iptables -t nat -F
iptables -t filter -F

iptables -t nat -A PREROUTING -i $INT_INTERFACE -p tcp -d 10.0.0.2 -j ACCEPT
iptables -t nat -A PREROUTING -i $INT_INTERFACE -p tcp -d 10.0.0.234 -j ACCEPT
iptables -t nat -A PREROUTING -i $INT_INTERFACE -p tcp -d 10.0.0.235 -j ACCEPT
iptables -t nat -A PREROUTING -i $INT_INTERFACE -p tcp -d 10.0.0.236 -j ACCEPT
iptables -t nat -A PREROUTING -i $INT_INTERFACE -p tcp -d 10.0.0.237 -j ACCEPT
iptables -t nat -A PREROUTING -i $INT_INTERFACE -p tcp -d 10.0.0.238 -j ACCEPT
iptables -t nat -A PREROUTING -i $INT_INTERFACE -p tcp -d 10.0.0.239 -j ACCEPT
iptables -t nat -A PREROUTING -i $INT_INTERFACE -p tcp -d 10.0.0.240 -j ACCEPT
iptables -t nat -A PREROUTING -i $INT_INTERFACE -p tcp -d 10.0.0.241 -j ACCEPT
iptables -t nat -A PREROUTING -i $INT_INTERFACE -p tcp -d 10.0.0.242 -j ACCEPT
iptables -t nat -A PREROUTING -i $INT_INTERFACE -p tcp -d 10.0.0.243 -j ACCEPT
iptables -t nat -A PREROUTING -i $INT_INTERFACE -p tcp -d 10.0.0.244 -j ACCEPT
iptables -t nat -A PREROUTING -i $INT_INTERFACE -p tcp -d 10.0.0.245 -j ACCEPT
iptables -t nat -A PREROUTING -i $INT_INTERFACE -p tcp -d 10.0.0.246 -j ACCEPT
iptables -t nat -A PREROUTING -i $INT_INTERFACE -p tcp -d 10.0.0.247 -j ACCEPT
iptables -t nat -A PREROUTING -i $INT_INTERFACE -p tcp -d 10.0.0.248 -j ACCEPT
iptables -t nat -A PREROUTING -i $INT_INTERFACE -p tcp -d 10.0.0.249 -j ACCEPT
iptables -t nat -A PREROUTING -i $INT_INTERFACE -p tcp -d 10.0.0.250 -j ACCEPT
iptables -t nat -A PREROUTING -i $INT_INTERFACE -p tcp -d 10.0.0.251 -j ACCEPT
iptables -t nat -A PREROUTING -i $INT_INTERFACE -p tcp -d 10.0.0.252 -j ACCEPT
iptables -t nat -A PREROUTING -i $INT_INTERFACE -p tcp -d 10.0.0.253 -j ACCEPT
iptables -t nat -A PREROUTING -i $INT_INTERFACE -p tcp -d 10.0.0.254 -j ACCEPT
iptables -t nat -A PREROUTING -i $INT_INTERFACE -p tcp -d 10.0.0.1 --dport 22 -j REDIRECT --to-ports 22
iptables -t nat -A PREROUTING -i $INT_INTERFACE -p udp -d 10.0.0.1 --dport 53 -j REDIRECT --to-ports 53
iptables -t nat -A PREROUTING -i $INT_INTERFACE -p tcp -d 10.0.0.1 --dport 80 -j REDIRECT --to-ports 80
iptables -t nat -A PREROUTING -i $INT_INTERFACE -p tcp -d 10.0.0.1 --dport 443 -j REDIRECT --to-ports 443

# to squid-i2p 
iptables -t nat -A OUTPUT     -d 10.191.0.1 -p tcp --dport 80 -j REDIRECT --to-port 3128
iptables -t nat -A PREROUTING -d 10.191.0.1 -p tcp --dport 80 -j REDIRECT --to-port 3128
iptables -t nat -A PREROUTING -i $INT_INTERFACE -p tcp -m tcp --sport 80 -d 10.191.0.1 -j REDIRECT --to-ports 3128

# ssh to tor socks proxy
# iptables -t nat -A OUTPUT -p tcp -d 10.0.0.0/8 --dport 22 -j REDIRECT --to-ports 9051
iptables -t nat -A PREROUTING -i $INT_INTERFACE -p tcp -d 10.0.0.0/8 --dport 22 -j REDIRECT --to-ports 9051

# to squid-tor
iptables -t nat -A PREROUTING -i $INT_INTERFACE -p tcp -d 10.0.0.0/8 -j DNAT --to 10.0.0.1:3129

# to squid http 
iptables -t nat -A PREROUTING -i $INT_INTERFACE -p tcp -m ndpi --http -j REDIRECT --to-ports 3130
iptables -t nat -A PREROUTING -i $INT_INTERFACE -p tcp --dport 80 -j DNAT --to 10.0.0.1:3130

# to squid https 
iptables -t nat -A PREROUTING -i $INT_INTERFACE -p tcp --dport 443 -j REDIRECT --to-ports 3131

# iptables nat
iptables -t nat -A POSTROUTING -o $EXT_INTERFACE -j MASQUERADE 

# ndpi protocole checking
#iptables -t mangle -I PREROUTING -m ndpi --dpi_check
#iptables -t mangle -I POSTROUTING -m ndpi --dpi_check

# Blocking ICMP from LAN_TO_WAN and from WAN_TO_LAN/ROUTER
iptables -A FORWARD -p ICMP -j DROP
iptables -A INPUT -p icmp -s 10.0.0.0/8 ! -d 10.0.0.0/8 -j DROP
#iptables -A OUTPUT -p icmp -o $EXT_INTERFACE -j ACCEPT
#iptables -A INPUT -p icmp --icmp-type echo-reply -s 0/0 -i $EXT_INTERFACE -j ACCEPT
#iptables -A INPUT -p icmp --icmp-type destination-unreachable -s 0/0 -i $EXT_INTERFACE -j ACCEPT
#iptables -A INPUT -p icmp --icmp-type time-exceeded -s 0/0 -i $EXT_INTERFACE -j ACCEPT
#iptables -A INPUT -p icmp -i $EXT_INTERFACE -j DROP


# iptables -A INPUT -p ICMP -i $INT_INTERFACE -j ACCEPT
# iptables -A OUTPUT -p ICMP -o $INT_INTERFACE -j ACCEPT
# iptables -A INPUT -p ICMP -j DROP
# iptables -A OUTPUT -p ICMP -j DROP
# iptables -A FORWARD -p ICMP -j DROP

# Blocking IPsec (All Directions)
iptables -A INPUT -m ndpi --ip_ipsec -j DROP
iptables -A OUTPUT -m ndpi --ip_ipsec -j DROP
iptables -A FORWARD -m ndpi --ip_ipsec -j DROP

# To config nxfilter
iptables -A INPUT -p tcp -s 10.0.0.0/24 -i br1 --dport 80 -j ACCEPT
iptables -A INPUT -p tcp -s 10.0.0.0/24 -i br1 --dport 443 -j ACCEPT

# Blocking DNS request from client to any servers other than librerouter
iptables -A INPUT -i $INT_INTERFACE -m ndpi --dns  -d 10.0.0.2 -j ACCEPT 
iptables -A INPUT -i $INT_INTERFACE -m ndpi --dns  -d 10.0.0.1 -j ACCEPT
iptables -A INPUT -i $INT_INTERFACE -m ndpi --dns  -d 0/0 -j DROP 
iptables -A FORWARD -m ndpi --dns ! -d 10.0.0.2 -j DROP

# Block any other TCP-UDP connections
iptables -P FORWARD DROP

## Enable Blacklist
#[ -e /etc/blacklists/blacklists-iptables.sh ] && /etc/blacklists/blacklists-iptables.sh &

# Configuring banks direct access
/var/banks_access.sh

# Stopping dnsmasq
kill -9 \`ps aux | grep dnsmasq | grep -v grep | awk {'print \$2'} | sed -n '1p'\` \
2> /dev/null
service unbound restart

# Starting easyrtc
nohup nodejs /opt/easyrtc/server_example/server.js &

# Starting Mailpile
/usr/bin/screen -dmS mailpile_init /opt/Mailpile/mp

# Restarting i2p
/etc/init.d/i2p restart

# Restarting tor
/etc/init.d/tor restart

# Time sync
ntpdate -s ntp.ubuntu.com

# Start suricata
ethtool -K lo rx off tso off gso off sg off gro off lro off
ifconfig lo mtu 1400
suricata -D -c /etc/suricata/suricata.yaml -i lo &

# Start logstash
#/opt/logstash/bin/logstash -f /etc/logstash/conf.d/logstash.conf & > /dev/null 2>&1

# Start Evebox
#evebox -e http://localhost:9200 &

# Start elasticsearch
#/etc/init.d/elasticsearch start

# Start Trac 
tracd -s -b 127.0.0.1 --port 8000 --auth="*,/opt/trac/libretrac/conf/passwd,librerouter" /opt/trac/libretrac &

# Start Redsocks
/opt/redsocks/redsocks -c /opt/redsocks/redsocks.conf &

# Start mlog2waffle
mlog2waffl &

# Start Snorby
cd /opt/snorby && bundle exec rails server -e production -b 127.0.0.1 &

# Start web robot.pl 
./root/libre_scripts/robot.pl

# Configuration for dnsmasq and lighttpd 
salt="GUI22391"
iptables=`iptables -L -n -t nat | grep 5353`;

if [ !-e /etc/gui/$salt ]; then
    dnsmasq -p 5353 -a 10.0.0.234
    lighthttpd -f /etc/lighttpd/lighttpd.conf
    iptables -t nat -I OUTPUT     -p udp --dport 53  -j DNAT --to-destination 10.0.0.234:5353
    iptables -t nat -I PREROUTING -p udp --dport 53  -j DNAT --to-destination 10.0.0.234:5353
    iptables -t nat -I OUTPUT     -p tcp --dport 80  -j DNAT --to-destination 10.0.0.234:2048
    iptables -t nat -I OUTPUT     -p tcp --dport 443 -j DNAT --to-destination 10.0.0.234:2048
else
    if [$iptables]; then
        iptables -t nat -D OUTPUT     -p udp --dport 53  -j DNAT --to-destination 10.0.0.234:5353
        iptables -t nat -D PREROUTING -p udp --dport 53  -j DNAT --to-destination 10.0.0.234:5353
        iptables -t nat -D OUTPUT     -p tcp --dport 80  -j DNAT --to-destination 10.0.0.234:2048
        iptables -t nat -D OUTPUT     -p tcp --dport 443 -j DNAT --to-destination 10.0.0.234:2048
        killall dnsmasq
        killall lighttpd
    fi
fi

exit 0
EOF

chmod +x /etc/rc.local

#/etc/rc.local | tee -a /var/libre_config.log
}


# ---------------------------------------------------------
# Function to configure ssh  
# ---------------------------------------------------------
configure_ssh()
{
echo "Configuring ssh ..."

# Allowing only V2 protocole
sed '/Protocol/c\Protocol 2' -i /etc/ssh/sshd_config

# Restarting ssh service
/etc/init.d/ssh restart
}


# ---------------------------------------------------------
# Function to configure TOR
# ---------------------------------------------------------
configure_tor()
{
echo "Configuring Tor server ..." | tee -a /var/libre_config.log
tordir=/var/lib/tor/hidden_service
for i in yacy nextcloud friendica mailpile easyrtc ssh gitlab trac redmine roundcube 
do

# Setting user and group to debian-tor
mkdir -p $tordir/$i
chown debian-tor:debian-tor $tordir/$i -R
rm -f $tordir/$i/*

done

# Setting permission to 2740 "rwxr-s---"
chmod 2700 $tordir/*

# Setting RUN_DAEMON to yes
# waitakey
# $EDITOR /etc/default/tor 
sed "s~RUN_DAEMON=.*~RUN_DAEMON=\"yes\"~g" -i /etc/default/tor


rm -f /etc/tor/torrc
#cp /usr/share/tor/tor-service-defaults-torrc /etc/tor/torrc
echo "" > /usr/share/tor/tor-service-defaults-torrc

echo "Configuring Tor hidden services" | tee -a /var/libre_config.log

chmod -R a+rx /var/lib/tor/

echo "
DataDirectory /var/lib/tor
PidFile /var/run/tor/tor.pid
RunAsDaemon 1
User debian-tor

ControlSocket /var/run/tor/control GroupWritable RelaxDirModeCheck
ControlSocketsGroupWritable 1
SocksPort unix:/var/run/tor/socks WorldWritable
SocksPort 127.0.0.1:9050

CookieAuthentication 1
CookieAuthFileGroupReadable 1
CookieAuthFile /var/run/tor/control.authcookie

Log notice file /var/log/tor/log

# ----- Hidden services ----- #

HiddenServiceDir /var/lib/tor/hidden_service/yacy
HiddenServicePort 80 10.0.0.251:80

HiddenServiceDir /var/lib/tor/hidden_service/nextcloud
HiddenServicePort 80 10.0.0.253:80
HiddenServicePort 443 10.0.0.253:443

#HiddenServiceDir /var/lib/tor/hidden_service/prosody
#HiddenServicePort 5222 127.0.0.1:5222
#HiddenServicePort 5269 127.0.0.1:5269

HiddenServiceDir /var/lib/tor/hidden_service/friendica
HiddenServicePort 80 10.0.0.252:80
HiddenServicePort 443 10.0.0.252:443 

HiddenServiceDir /var/lib/tor/hidden_service/mailpile
HiddenServicePort 80 10.0.0.254:80
HiddenServicePort 443 10.0.0.254:443

HiddenServiceDir /var/lib/tor/hidden_service/easyrtc
HiddenServicePort 80 10.0.0.250:80
HiddenServicePort 443 10.0.0.250:443

HiddenServiceDir /var/lib/tor/hidden_service/ssh
HiddenServicePort 22 10.0.0.1:22

HiddenServiceDir /var/lib/tor/hidden_service/gitlab
HiddenServicePort 80 10.0.0.247:80
HiddenServicePort 443 10.0.0.247:443

HiddenServiceDir /var/lib/tor/hidden_service/trac
HiddenServicePort 80 10.0.0.248:80
HiddenServicePort 443 10.0.0.248:443

HiddenServiceDir /var/lib/tor/hidden_service/redmine
HiddenServicePort 80 10.0.0.249:80
HiddenServicePort 443 10.0.0.249:443

HiddenServiceDir /var/lib/tor/hidden_service/roundcube
HiddenServicePort 80 10.0.0.243:80
HiddenServicePort 443 10.0.0.243:443

# ----- Tor DNS ----- #

DNSPort   127.0.0.1:9053
VirtualAddrNetworkIPv4 10.0.0.0/8
AutomapHostsOnResolve 1
" >>  /etc/tor/torrc

service apache2 stop 
sleep 10
service tor restart | tee -a /var/libre_config.log

LOOP_S=0
LOOP_N=0
while [ $LOOP_S -lt 1 ]
do
if [ -e "/var/lib/tor/hidden_service/yacy/hostname" ]; then
echo "Tor successfully configured" | tee -a /var/libre_config.log
LOOP_S=1
else
sleep 1
LOOP_N=$((LOOP_N + 1))
fi
# Wail up to 60 s for tor hidden services to become available
if [ $LOOP_N -eq 60 ]; then
echo "Error: Unable to configure tor. Exiting ..." | tee -a /var/libre_config.log
exit 1 
fi 
done
}


# ---------------------------------------------------------
# Function to configure I2PD services
# ---------------------------------------------------------
configure_i2pd()
{
echo "Configuring i2pd server ..." | tee -a /var/libre_config.log

# i2pd hidden services
cat << EOF > /var/lib/i2pd/tunnels.conf

[conference-on-i2pd]
type=http
host=10.0.0.250
port=80
keys=conference.dat

[social-on-i2pd]
type=http
host=10.0.0.252
port=80
keys=social.dat

[gitlab-on-i2pd]
type=http
host=10.0.0.247
port=80
keys=gitlab.dat

[email-on-i2pd]
type=http
host=10.0.0.254
port=80
keys=email.dat

[storage-on-i2pd]
type=http
host=10.0.0.253
port=80
keys=storage.dat

[redmine-on-i2pd]
type=http
host=10.0.0.249
port=80
keys=redmine.dat

[roundcube-on-i2pd]
type=http
host=10.0.0.243
port=80
keys=roundcube.dat

[trac-on-i2pd]
type=http
host=10.0.0.248
port=80
keys=trac.dat

[search-on-i2pd]
type=http
host=10.0.0.251
port=80
keys=search.dat
EOF

# Configuring i2pd web interface
# sed -i '117s/address = 127.0.0.1/address = 10.0.0.1/' /etc/i2pd/i2pd.conf

# Restarting i2pd
service i2pd restart | tee -a /var/libre_config.log

sleep 10

# Check if services are ready
LOOP_S=0
LOOP_N=0
echo "Configuring i2pd hidden services ..." | tee -a /var/libre_config.log
while [ $LOOP_S -lt 1 ]
do
if [ `ls /var/lib/i2pd/destinations/ 2>/dev/null | wc -l` -eq 9 ]; then
echo "i2pd successfully configured" | tee -a /var/libre_config.log
LOOP_S=1
else
sleep 1
LOOP_N=$((LOOP_N + 1))
fi
# Wail up to 120s for i2pd hidden services to become available
if [ $LOOP_N -eq 160 ]; then
echo "Error: Unable to configure i2pd. Exiting ..." | tee -a /var/libre_config.log
exit 1
fi
done

sleep 1

# Get hidden servies domain names.
echo "Getting i2pd hidden services names ..." | tee -a /var/libre_config.log
wget -O i2pd_domain_name_txt "http://127.0.0.1:7070/?page=i2p_tunnels"

I2P_SEARCH=`cat i2pd_domain_name_txt | grep search-on-i2pd | awk -F "=" {'print $4'} | awk -F "\"" {'print $1".b32.i2p"'}`
echo $I2P_SEARCH | tee -a /var/libre_config.log

I2P_SOCIAL=`cat i2pd_domain_name_txt | grep social-on-i2pd | awk -F "=" {'print $4'} | awk -F "\"" {'print $1".b32.i2p"'}`
echo $I2P_SOCIAL | tee -a /var/libre_config.log

I2P_CONFERENCE=`cat i2pd_domain_name_txt | grep conference-on-i2pd | awk -F "=" {'print $4'} | awk -F "\"" {'print $1".b32.i2p"'}`
echo $I2P_CONFERENCE | tee -a /var/libre_config.log

I2P_EMAIL=`cat i2pd_domain_name_txt | grep email-on-i2pd | awk -F "=" {'print $4'} | awk -F "\"" {'print $1".b32.i2p"'}`
echo $I2P_EMAIL | tee -a /var/libre_config.log

I2P_GITLAB=`cat i2pd_domain_name_txt | grep gitlab-on-i2pd | awk -F "=" {'print $4'} | awk -F "\"" {'print $1".b32.i2p"'}`
echo $I2P_GITLAB | tee -a /var/libre_config.log

I2P_TRAC=`cat i2pd_domain_name_txt | grep trac-on-i2pd | awk -F "=" {'print $4'} | awk -F "\"" {'print $1".b32.i2p"'}`
echo $I2P_TRAC | tee -a /var/libre_config.log

I2P_ROUNDCUBE=`cat i2pd_domain_name_txt | grep roundcube-on-i2pd | awk -F "=" {'print $4'} | awk -F "\"" {'print $1".b32.i2p"'}`
echo $I2P_ROUNDCUBE | tee -a /var/libre_config.log

I2P_REDMINE=`cat i2pd_domain_name_txt | grep redmine-on-i2pd | awk -F "=" {'print $4'} | awk -F "\"" {'print $1".b32.i2p"'}`
echo $I2P_REDMINE | tee -a /var/libre_config.log

I2P_STORAGE=`cat i2pd_domain_name_txt | grep storage-on-i2pd | awk -F "=" {'print $4'} | awk -F "\"" {'print $1".b32.i2p"'}`
echo $I2P_STORAGE | tee -a /var/libre_config.log

# Cleaning up
rm -rf i2pd_domain_name_txt
}


# ---------------------------------------------------------
# Function to configure Unbound DNS server
# ---------------------------------------------------------
configure_unbound() 
{
echo "Configuring unbound DNS server ..." | tee -a /var/libre_config.log
echo '# Unbound configuration file for Debian.
#
# See the unbound.conf(5) man page.
#
# See /usr/share/doc/unbound/examples/unbound.conf for a commented
# reference config file.

server:
# The following line will configure unbound to perform cryptographic
# DNSSEC validation using the root trust anchor.

# Specify the interface to answer queries from by ip address.
interface: 10.0.0.1

# Port to answer queries
port: 53

# Serve ipv4 requests
do-ip4: yes

# Serve ipv6 requests
do-ip6: no

# Enable UDP
do-udp: yes

# Enable TCP
do-tcp: yes

# Not to answer id.server and hostname.bind queries
hide-identity: yes

# Not to answer version.server and version.bind queries
hide-version: yes

# Use 0x20-encoded random bits in the query 
use-caps-for-id: yes

# Cache minimum time to live
Cache-min-ttl: 3600

# Cache maximum time to live
cache-max-ttl: 86400

# Perform prefetching
prefetch: yes

# Number of threads 
num-threads: 2

## Unbound optimization ##

# Number od slabs
msg-cache-slabs: 4
rrset-cache-slabs: 4
infra-cache-slabs: 4
key-cache-slabs: 4

# Size pf cache memory
rrset-cache-size: 128m
msg-cache-size: 64m

# Buffer size for UDP port 53
so-rcvbuf: 1m

# Unwanted replies maximum number
unwanted-reply-threshold: 10000

# Define which network ips are allowed to make queries to this server.
access-control: 10.0.0.0/8 allow
access-control: 127.0.0.1/8 allow
access-control: 0.0.0.0/0 refuse

# Configure DNSSEC validation
# librenet, onion and i2p domains are not checked for DNSSEC validation
#    auto-trust-anchor-file: "/var/lib/unbound/root.key"
do-not-query-localhost: no
#    domain-insecure: "librenet"
#    domain-insecure: "onion"
#    domain-insecure: "i2p"

#Local destinations
local-zone: "librenet" static
local-data: "warning.librerouter.net. IN A 10.0.0.1"
local-data: "i2p.librenet. IN A 10.0.0.1"
local-data: "tahoe.librenet. IN A 10.0.0.1"
local-data: "initial.librerouter.net. IN A 10.0.0.234"
local-data: "dns.librerouter.net. IN A 10.0.0.235"
local-data: "gui.librerouter.net. IN A 10.0.0.236"
local-data: "webconsole.librerouter.net. IN A 10.0.0.237"
local-data: "waffle.librerouter.net. IN A 10.0.0.238"
local-data: "snorby.librerouter.net. IN A 10.0.0.239"
local-data: "sogo.librerouter.net. IN A 10.0.0.241"
local-data: "postfix.librerouter.net. IN A 10.0.0.242"
local-data: "roundcube.librerouter.net. IN A 10.0.0.243"
local-data: "ntop.librerouter.net. IN A 10.0.0.244"
local-data: "webmin.librerouter.net. IN A 10.0.0.245"
local-data: "squidguard.librerouter.net. IN A 10.0.0.246"
local-data: "gitlab.librerouter.net. IN A 10.0.0.247"
local-data: "trac.librerouter.net. IN A 10.0.0.248"
local-data: "redmine.librerouter.net. IN A 10.0.0.249"
local-data: "conference.librerouter.net. IN A 10.0.0.250"
local-data: "search.librerouter.net. IN A 10.0.0.251"
local-data: "social.librerouter.net. IN A 10.0.0.252"
local-data: "storage.librerouter.net. IN A 10.0.0.253"
local-data: "email.librerouter.net. IN A 10.0.0.254"' > /etc/unbound/unbound.conf

for i in $(ls /var/lib/tor/hidden_service/)
do
if [ $i == "easyrtc" ]; then
echo "local-data: \"$i.librenet. IN A 10.0.0.250\"" \
>> /etc/unbound/unbound.conf
fi
if [ $i == "yacy" ]; then
echo "local-data: \"$i.librenet. IN A 10.0.0.251\"" \
>> /etc/unbound/unbound.conf
fi
if [ $i == "friendica" ]; then
echo "local-data: \"$i.librenet. IN A 10.0.0.252\"" \
>> /etc/unbound/unbound.conf
fi
if [ $i == "nextcloud" ]; then
echo "local-data: \"$i.librenet. IN A 10.0.0.253\"" \
>> /etc/unbound/unbound.conf
fi
if [ $i == "mailpile" ]; then
echo "local-data: \"$i.librenet. IN A 10.0.0.254\"" \
>> /etc/unbound/unbound.conf
fi
if [ $i == "gitlab" ]; then
echo "local-data: \"$i.librenet. IN A 10.0.0.247\"" \
>> /etc/unbound/unbound.conf
fi
if [ $i == "trac" ]; then
echo "local-data: \"$i.librenet. IN A 10.0.0.248\"" \
>> /etc/unbound/unbound.conf
fi
if [ $i == "redmine" ]; then
echo "local-data: \"$i.librenet. IN A 10.0.0.249\"" \
>> /etc/unbound/unbound.conf
fi
if [ $i == "ssh" ]; then
echo "local-data: \"$i.librenet. IN A 10.0.0.1\"" \
>> /etc/unbound/unbound.conf
fi
done

for i in $(ls /var/lib/tor/hidden_service/)
do
hn="$(cat /var/lib/tor/hidden_service/$i/hostname 2>/dev/null )"
if [ -n "$hn" ]; then
echo "local-zone: \"$hn.\" static" >> /etc/unbound/unbound.conf
if [ $i == "easyrtc" ]; then
echo "local-data: \"$hn. IN A 10.0.0.250\"" >> /etc/unbound/unbound.conf
fi
if [ $i == "yacy" ]; then
echo "local-data: \"$hn. IN A 10.0.0.251\"" >> /etc/unbound/unbound.conf
fi
if [ $i == "friendica" ]; then
echo "local-data: \"$hn. IN A 10.0.0.252\"" >> /etc/unbound/unbound.conf
fi
if [ $i == "nextcloud" ]; then
echo "local-data: \"$hn. IN A 10.0.0.253\"" >> /etc/unbound/unbound.conf
fi
if [ $i == "mailpile" ]; then
echo "local-data: \"$hn. IN A 10.0.0.254\"" >> /etc/unbound/unbound.conf
fi
if [ $i == "gitlab" ]; then
echo "local-data: \"$hn. IN A 10.0.0.247\"" >> /etc/unbound/unbound.conf
fi
if [ $i == "trac" ]; then
echo "local-data: \"$hn. IN A 10.0.0.248\"" >> /etc/unbound/unbound.conf
fi
if [ $i == "redmine" ]; then
echo "local-data: \"$hn. IN A 10.0.0.249\"" >> /etc/unbound/unbound.conf
fi
if [ $i == "ssh" ]; then
echo "local-data: \"$hn. IN A 10.0.0.1\"" >> /etc/unbound/unbound.conf
fi
fi
done

echo '
# I2P domains will be resolved us 10.191.0.1 
local-zone: "i2p." redirect
local-data: "i2p. IN A 10.191.0.1"

# Include social networks domains list configuration
include: /etc/unbound/socialnet_domain.list.conf

# Include search engines domains list configuration
include: /etc/unbound/searchengines_domain.list.conf

# Include webmail domains list configuration
include: /etc/unbound/webmail_domain.list.conf

# Include chat domains list configuration
include: /etc/unbound/chat_domain.list.conf

# Include storage domains list configuration
include: /etc/unbound/storage_domain.list.conf

# Include block domains list configuration
include: /etc/unbound/block_domain.list.conf

# .ounin domains will be resolved by TOR DNS 
forward-zone:
name: "onion"
forward-addr: 127.0.0.1@9053

# Forward rest of zones to DjDNS
forward-zone:
name: "."
forward-addr: 10.0.0.1@43

' >> /etc/unbound/unbound.conf

# Extracting classified domain list package
echo "Extracting files ..." | tee -a /var/libre_config.log
cp /opt/shallalist.tar.gz .
tar -xf shallalist.tar.gz
if [ $? -ne 0 ]; then
echo "Error: Unable to extract domains list. Exithing" | tee -a /var/libre_config.log
exit 6
fi

# Configuring social network domains list
echo "Configuring domain list ..." | tee -a /var/libre_config.log
find BL/socialnet -name domains -exec cat {} \; > socialnet_domain.list
find BL/searchengines -name domains -exec cat {} \; > searchengines_domain.list
find BL/webmail -name domains -exec cat {} \; > webmail_domain.list
find BL/chat -name domains -exec cat {} \; > chat_domain.list
find BL/downloads -name domains -exec cat {} \; > storage_domain.list
find BL/spyware -name domains -exec cat {} \; > block_domain.list
find BL/redirector -name domains -exec cat {} \; >> block_domain.list
find BL/tracker -name domains -exec cat {} \; >> block_domain.list

# Deleting old files
rm -rf shallalist 	
rm -rf shallalist.tar.gz

# Creating chat domains list configuration file
cat chat_domain.list | \
awk {'print "local-data: \"" $1 " IN A 10.0.0.250\""'} \
> /etc/unbound/chat_domain.list.conf
cat chat_domain.list | \
awk {'print "local-data: \"www." $1 " IN A 10.0.0.250\""'} \
>> /etc/unbound/chat_domain.list.conf

# Adding skype to chat domain list
echo "local-data: \"skype.com IN A 10.0.0.250\"
local-data: \"www.skype.com IN A 10.0.0.250\"
" >> /etc/unbound/chat_domain.list.conf

# Creating search engines domains list configuration file
cat searchengines_domain.list | \
awk {'print "local-data: \"" $1 " IN A 10.0.0.251\""'} \
> /etc/unbound/searchengines_domain.list.conf
cat searchengines_domain.list | \
awk {'print "local-data: \"www." $1 " IN A 10.0.0.251\""'} \
>> /etc/unbound/searchengines_domain.list.conf

# Creating social networks domains list configuration file
cat socialnet_domain.list | \
awk {'print "local-data: \"" $1 " IN A 10.0.0.252\""'} \
> /etc/unbound/socialnet_domain.list.conf
cat socialnet_domain.list | \
awk {'print "local-data: \"www." $1 " IN A 10.0.0.252\""'} \
>> /etc/unbound/socialnet_domain.list.conf

# Creating storage domains list configuration file
cat storage_domain.list | \
awk {'print "local-data: \"" $1 " IN A 10.0.0.253\""'} \
> /etc/unbound/storage_domain.list.conf
cat storage_domain.list | \
awk {'print "local-data: \"www." $1 " IN A 10.0.0.253\""'} \
>> /etc/unbound/storage_domain.list.conf

# Creating  webmail domains list configuration file
cat webmail_domain.list | \
awk {'print "local-data: \"" $1 " IN A 10.0.0.254\""'} \
> /etc/unbound/webmail_domain.list.conf
cat webmail_domain.list | \
awk {'print "local-data: \"www." $1 " IN A 10.0.0.254\""'} \
>> /etc/unbound/webmail_domain.list.conf

# Creating  block domains list configuration file
cat block_domain.list | \
awk {'print "local-data: \"" $1 " IN A 10.0.0.2\""'} \
> /etc/unbound/block_domain.list.conf
cat block_domain.list | \
awk {'print "local-data: \"www." $1 " IN A 10.0.0.2\""'} \
>> /etc/unbound/block_domain.list.conf

# Deleting old files
rm -rf socialnet_domain.list
rm -rf searchengines_domain.list
rm -rf webmail_domain.list
rm -rf chat_domain.list
rm -rf storage_domain.list
rm -rf block_domain.list

# Updating DNSSEC root trust anchor
unbound-anchor -a "/var/lib/unbound/root.key"

# There is a need to stop dnsmasq before starting unbound
echo "Stoping dnsmasq ..."
if ps aux | grep -w "dnsmasq" | grep -v "grep" > /dev/null;   then
kill -9 `ps aux | grep dnsmasq | grep -v grep | awk {'print $2'} | sed -n '1p'`
fi

#     echo "
#	# Stopping dnsmasq
#	kill -9 \`ps aux | grep dnsmasq | awk {'print \$2'} | sed -n '1p'\` \
#	2> /dev/null
#	" >> /etc/rc.local
#
#	echo "service unbound restart" >> /etc/rc.local

echo "Starting Unbound DNS server ..." | tee -a /var/libre_config.log
service unbound restart | tee -a /var/libre_config.log
if ps aux | grep -w "unbound" | grep -v "grep" > /dev/null; then
echo "Unbound DNS server successfully started." | tee -a /var/libre_config.log
else
echo "Error: Unable to start unbound DNS server. Exiting" | tee -a /var/libre_config.log
exit 3
fi
}


# ---------------------------------------------------------
# Function to configure DNSCrypt
# ---------------------------------------------------------
configure_dnscrypt()
{
echo 'Configuring DNSCrypt server ...' | tee -a /var/libre_config.log
sed -i '/Daemonize/d' /usr/local/etc/dnscrypt-proxy.conf
sed -i '/ResolverName/d' /usr/local/etc/dnscrypt-proxy.conf
sed -i '/LocalAddress/d' /usr/local/etc/dnscrypt-proxy.conf
sed -i '/QueryLogFile/d' /usr/local/etc/dnscrypt-proxy.conf
sed -i '/LogFile/d' /usr/local/etc/dnscrypt-proxy.conf
echo 'ResolverName fvz-anyone
Daemonize yes
LocalAddress 10.0.0.1:43' >> /usr/local/etc/dnscrypt-proxy.conf
echo 'Starting DNSCrypt server ...' | tee -a /var/libre_config.log
/usr/local/sbin/dnscrypt-proxy /usr/local/etc/dnscrypt-proxy.conf &>> /var/libre_config.log
chattr -i /etc/resolv.conf
echo 'nameserver 10.0.0.1' > /etc/resolv.conf
chattr +i /etc/resolv.conf

# Run after boot (We need add dnscrypt to systemd)
echo '
#!/bin/bash
/usr/local/sbin/dnscrypt-proxy /usr/local/etc/dnscrypt-proxy.conf' > /usr/bin/dnscrypt-proxy.sh
chmod +x /usr/bin/dnscrypt-proxy.sh
sed -i '/exit/d' /etc/rc.local
sed -i 'dnscrypt-proxy/d' /etc/rc.local
echo '/bin/bash /usr/bin/dnscrypt-proxy.sh &
exit 0' >> /etc/rc.local
}


# ---------------------------------------------------------
# Configure yacy search engine
# ---------------------------------------------------------
configure_yacy()
{
echo "Configuring yacy search engine ..." | tee -a /var/libre_config.log

# Configure yacy administrative account
YACY_PASS=`pwgen 10 1`
/usr/share/yacy/bin/passwd.sh $YACY_PASS

# Yacy connect to Tor
sed 's/remoteProxyUse.*/remoteProxyUse=true/g' -i /etc/yacy/yacy.conf
sed 's/remoteProxyHost.*/remoteProxyHost=127.0.0.1/g' -i /etc/yacy/yacy.conf
sed 's/remoteProxyPort.*/remoteProxyPort=3129/g' -i /etc/yacy/yacy.conf
}


# ---------------------------------------------------------
# Function to configure Friendica local service
# ---------------------------------------------------------
configure_friendica()
{
echo "Configuring Friendica local service ..." | tee -a /var/libre_config.log
if [ ! -e  /var/lib/mysql/frnd ]; then

# Defining MySQL user and password variables
# MYSQL_PASS="librerouter"
MYSQL_USER="root"

# Creating MySQL database frnd for friendica local service
echo "CREATE DATABASE frnd;" \
| mysql -u "$MYSQL_USER" -p"$MYSQL_PASS" 
fi

# Inserting friendica database
sed -i  s/utf8mb4/utf8/g /var/www/friendica/database.sql
mysql -u "$MYSQL_USER" -p"$MYSQL_PASS" frnd < /var/www/friendica/database.sql

if [ -z "$(grep "friendica/include/poller" /etc/crontab)" ]; then
echo '*/10 * * * * /usr/bin/php /var/www/friendica/include/poller.php' >> /etc/crontab
fi

# Creating friendica configuration
echo "
<?php

\$db_host = 'localhost';
\$db_user = 'root';
\$db_pass = '$MYSQL_PASS';
\$db_data = 'frnd';

\$a->path = '';
\$default_timezone = 'America/Los_Angeles';
\$a->config['sitename'] = \"My Friend Network\";
\$a->config['register_policy'] = REGISTER_OPEN;
\$a->config['register_text'] = '';
\$a->config['admin_email'] = 'admin@librerouter.net';
\$a->config['max_import_size'] = 200000;
\$a->config['system']['maximagesize'] = 800000;
\$a->config['php_path'] = '/usr/bin/php';
\$a->config['system']['huburl'] = '[internal]';
\$a->config['system']['rino_encrypt'] = true;
\$a->config['system']['theme'] = 'duepuntozero';
\$a->config['system']['no_regfullname'] = true;
\$a->config['system']['directory'] = 'http://dir.friendi.ca';
" > /var/www/friendica/.htconfig.php

}


# ---------------------------------------------------------
# Function to configure EasyRTC local service
# ---------------------------------------------------------
configure_easyrtc()
{
echo "Starting EasyRTC local service ..." | tee -a /var/libre_config.log
if [ ! -e /opt/easyrtc/server_example/server.js ]; then
echo "Can not find EasyRTC server confiugration. Exiting ..." | tee -a /var/libre_config.log
exit 4
fi

cat << EOF > /opt/easyrtc/server_example/server.js 
// Load required modules
var https    = require("https");              // http server core module
var express = require("express");           // web framework external module
var serveStatic = require('serve-static');  // serve static files
var socketIo = require("socket.io");        // web socket external module
var easyrtc = require("../");               // EasyRTC external module
var fs = require("fs");

// Set process name
process.title = "node-easyrtc";

// Setup and configure Express http server. Expect a subfolder called "static" to be the web root.
var app = express();
app.use(serveStatic('static', {'index': ['index.html']}));

// Start Express http server on port 8443
var webServer = https.createServer(
{
key:  fs.readFileSync("/etc/ssl/apache/conference/conference_librerouter_net.key"),
cert: fs.readFileSync("/etc/ssl/apache/conference/conference_bundle.crt")
},
app).listen(8443);

// Start Socket.io so it attaches itself to Express server
var socketServer = socketIo.listen(webServer, {"log level":1});

easyrtc.setOption("logLevel", "debug");

// Overriding the default easyrtcAuth listener, only so we can directly access its callback
easyrtc.events.on("easyrtcAuth", function(socket, easyrtcid, msg, socketCallback, callback) {
easyrtc.events.defaultListeners.easyrtcAuth(socket, easyrtcid, msg, socketCallback, function(err, connectionObj){
if (err || !msg.msgData || !msg.msgData.credential || !connectionObj) {
    callback(err, connectionObj);
    return;
}

connectionObj.setField("credential", msg.msgData.credential, {"isShared":false});

console.log("["+easyrtcid+"] Credential saved!", connectionObj.getFieldValueSync("credential"));

callback(err, connectionObj);
});
});

// To test, lets print the credential to the console for every room join!
easyrtc.events.on("roomJoin", function(connectionObj, roomName, roomParameter, callback) {
console.log("["+connectionObj.getEasyrtcid()+"] Credential retrieved!", connectionObj.getFieldValueSync("credential"));
easyrtc.events.defaultListeners.roomJoin(connectionObj, roomName, roomParameter, callback);
});

// Start EasyRTC server
var rtc = easyrtc.listen(app, socketServer, null, function(err, rtcRef) {
console.log("Initiated");

rtcRef.events.on("roomCreate", function(appObj, creatorConnectionObj, roomName, roomOptions, callback) {
console.log("roomCreate fired! Trying to create: " + roomName);

appObj.events.defaultListeners.roomCreate(appObj, creatorConnectionObj, roomName, roomOptions, callback);
});
});

//listen on port 8443
webServer.listen(8443, function () {
console.log('listening on http://localhost:8443');
});
EOF

# sed -i '/function connect() {/a easyrtc.setSocketUrl(":8443");' /opt/easyrtc/node_modules/easyrtc/demos/js/*.js

cd /opt/easyrtc/server_example

# Starting EasyRTC server
nohup nodejs server & 

echo ""
cd
}


# ---------------------------------------------------------
# Function to configure Owncloud local service 
# ---------------------------------------------------------
configure_nextcloud()
{
echo "Configuring nextcloud local service ..." | tee -a /var/libre_config.log

# Getting nextcloud onion service name
SERVER_NEXTCLOUD="$(cat /var/lib/tor/hidden_service/nextcloud/hostname 2>/dev/null)"

chown -R www-data /var/www/nextcloud

# Create Nextcloud database
if [ ! -e  /var/lib/mysql/nextcloud ]; then

# Defining MySQL user and password variables
MYSQL_USER="root"

# Creating MySQL database frnd for friendica local service
echo "CREATE DATABASE nextcloud;" \
| mysql -u "$MYSQL_USER" -p"$MYSQL_PASS"
fi

# Removing default config
rm -rf /var/www/nextcloud/config/config.php

# Generate password
CLOUD_PASS=`pwgen 10 1`

# Generate autoconfig
cat << EOF > /var/www/nextcloud/config/autoconfig.php
<?php
\$AUTOCONFIG = array (
'dbtype' => "mysql",
'dbname' => "nextcloud",
'dbuser' => "root",
'dbpass' => "$MYSQL_PASS",
'dbhost' => "localhost",
'dbtableprefix' => "",
'adminlogin' => "admin",
'adminpass' => "$CLOUD_PASS",
'directory' => "/var/www/nextcloud/data",
'trusted_domains' =>
  array (
    0 => "storage.librerouter.net",
    1 => "gui.librerouter.net",
  ),
  'overwrite.cli.url' => "https://storage.librerouter.net",
  'default_language' => "en",
);
EOF

# Setting permission
chmod 777 /var/www/nextcloud/config/autoconfig.php

# Configure Nextcloud Installation page
#cat << EOF > /var/www/nextcloud/core/templates/installation.php
#<?php
#script('core', [
#        'jquery-showpassword',
#        'installation'
#]);
#?>
#<input type='hidden' id='hasMySQL' value='<?php p(\$_['hasMySQL']) ?>'>
#<input type='hidden' id='hasSQLite' value='<?php p(\$_['hasSQLite']) ?>'>
#<input type='hidden' id='hasPostgreSQL' value='<?php p(\$_['hasPostgreSQL']) ?>'>
#<input type='hidden' id='hasOracle' value='<?php p(\$_['hasOracle']) ?>'>
#<form action="index.php" method="post">
#<input type="hidden" name="install" value="true">
#        <?php if(count(\$_['errors']) > 0): ?>
#        <fieldset class="warning">
#                <legend><strong><?php p(\$l->t('Error'));?></strong></legend>
#                <?php foreach(\$_['errors'] as \$err): ?>
#                <p>
#                        <?php if(is_array(\$err)):?>
#                                <?php print_unescaped(\$err['error']); ?>
#                                <span class='hint'><?php print_unescaped(\$err['hint']); ?></span>
#                        <?php else: ?>
#                                <?php print_unescaped(\$err); ?>
#                        <?php endif; ?>
#                </p>
#                <?php endforeach; ?>
#        </fieldset>
#        <?php endif; ?>
#        <?php if(!\$_['htaccessWorking']): ?>
#        <fieldset class="warning">
#                <legend><strong><?php p(\$l->t('Security warning'));?></strong></legend>
#                <p><?php p(\$l->t('Your data directory and files are probably accessible from the internet because the .htaccess file does not work.'));?><br>
#                <?php print_unescaped(\$l->t(
#                        'For information how to properly configure your server, please see the <a href="%s" target="_blank" rel="noreferrer">documentation</a>.',
#                        link_to_docs('admin-install')
#                )); ?></p>
#        </fieldset>
#        <?php endif; ?>
#        <fieldset id="adminaccount">
#                <legend><?php print_unescaped(\$l->t( 'Create an <strong>admin account</strong>' )); ?></legend>
#                <p class="grouptop">
#                        <input type="text" name="adminlogin" id="adminlogin"
#                                placeholder="<?php p(\$l->t( 'Username' )); ?>"
#                                value="<?php p(\$_['adminlogin']); ?>"
#                                autocomplete="off" autocapitalize="none" autocorrect="off" autofocus required>
#                        <label for="adminlogin" class="infield"><?php p(\$l->t( 'Username' )); ?></label>
#                </p>
#                <p class="groupbottom">
#                        <input type="password" name="adminpass" data-typetoggle="#show" id="adminpass"
#                                placeholder="<?php p(\$l->t( 'Password' )); ?>"
#                                value="<?php p(\$_['adminpass']); ?>"
#                                autocomplete="off" autocapitalize="none" autocorrect="off" required>
#                        <label for="adminpass" class="infield"><?php p(\$l->t( 'Password' )); ?></label>
#                        <input type="checkbox" id="show" name="show">
#                        <label for="show"></label>
#                </p>
#        </fieldset>
#
#        <?php if(!\$_['directoryIsSet'] OR !\$_['dbIsSet'] OR count(\$_['errors']) > 0): ?>
#        <fieldset id="advancedHeader">
#                <legend><a id="showAdvanced"><?php p(\$l->t( 'Storage & database' )); ?> <img src="<?php print_unescaped(image_path('', 'actions/caret.svg')); ?>" /></a></legend>
#        </fieldset>
#        <?php endif; ?>
#
#        <?php if(!\$_['directoryIsSet'] OR count(\$_['errors']) > 0): ?>
#        <fieldset id="datadirField">
#                <div id="datadirContent">
#                        <label for="directory"><?php p(\$l->t( 'Data folder' )); ?></label>
#                        <input type="text" name="directory" id="directory"
#                                placeholder="<?php p(OC::\$SERVERROOT.'/data'); ?>"
#                                value="<?php p(\$_['directory']); ?>"
#                                autocomplete="off" autocapitalize="none" autocorrect="off">
#                </div>
#        </fieldset>
#        <?php endif; ?>
#
#        <?php if(!\$_['dbIsSet'] OR count(\$_['errors']) > 0): ?>
#        <fieldset id='databaseBackend'>
#                <?php if(\$_['hasMySQL'] or \$_['hasPostgreSQL'] or \$_['hasOracle'])
#                        \$hasOtherDB = true; else \$hasOtherDB =false; //other than SQLite ?>
#                <legend><?php p(\$l->t( 'Configure the database' )); ?></legend>
#                <div id="selectDbType">
#                <?php foreach(\$_['databases'] as \$type => \$label): ?>
#                <?php if(count(\$_['databases']) === 1): ?>
#                <p class="info">
#                        <?php p(\$l->t( 'Only %s is available.', array(\$label) )); ?>
#                        <?php p(\$l->t( 'Install and activate additional PHP modules to choose other database types.' )); ?><br>
#                        <a href="<?php print_unescaped(link_to_docs('admin-source_install')); ?>" target="_blank" rel="noreferrer">
#                                <?php p(\$l->t( 'For more details check out the documentation.' )); ?> �~F~W</a>
#                </p>
#                <input type="hidden" id="dbtype" name="dbtype" value="<?php p(\$type) ?>">
#                <?php else: ?>
#                <input type="radio" name="dbtype" value="<?php p(\$type) ?>" id="<?php p(\$type) ?>"
#                        <?php print_unescaped(\$_['dbtype'] === \$type ? 'checked="checked" ' : '') ?>/>
#                <label class="<?php p(\$type) ?>" for="<?php p(\$type) ?>"><?php p(\$label) ?></label>
#                <?php endif; ?>
#                <?php endforeach; ?>
#                </div>
#        </fieldset>
#               <?php if(\$hasOtherDB): ?>
#                <fieldset id='databaseField'>
#                <div id="use_other_db">
#                        <p class="grouptop">
#                                <label for="dbuser" class="infield"><?php p(\$l->t( 'Database user' )); ?></label>
#                                <input type="text" name="dbuser" id="dbuser"
#                                        placeholder="<?php p(\$l->t( 'Database user' )); ?>"
#                                        value="root"
#                                        autocomplete="off" autocapitalize="none" autocorrect="off">
#                        </p>
#                        <p class="groupmiddle">
#                                <label for="dbpass" class="infield"><?php p(\$l->t( 'Database password' )); ?></label>
#                                <input type="password" name="dbpass" id="dbuser"
#                                        placeholder="<?php p(\$l->t( 'Database password' )); ?>"
#                                        value="$MYSQL_PASS"
#                                        autocomplete="off" autocapitalize="none" autocorrect="off">
#                        </p>
#                        <p class="groupmiddle">
#                                <label for="dbname" class="infield"><?php p(\$l->t( 'Database name' )); ?></label>
#                                <input type="text" name="dbname" id="dbname"
#                                        placeholder="<?php p(\$l->t( 'Database name' )); ?>"
#                                        value="nextcloud"
#                                        autocomplete="off" autocapitalize="none" autocorrect="off"
#                                        pattern="[0-9a-zA-Z$_-]+">
#                        </p>
#                        <?php if(\$_['hasOracle']): ?>
#                        <div id="use_oracle_db">
#                                <p class="groupmiddle">
#                                        <label for="dbtablespace" class="infield"><?php p(\$l->t( 'Database tablespace' )); ?></label>
#                                        <input type="text" name="dbtablespace" id="dbtablespace"
#                                                placeholder="<?php p(\$l->t( 'Database tablespace' )); ?>"
#                                                value="<?php p(\$_['dbtablespace']); ?>"
#                                                autocomplete="off" autocapitalize="none" autocorrect="off">
#                                </p>
#                        </div>
#                        <?php endif; ?>
#                        <p class="groupbottom">
#                                <label for="dbhost" class="infield"><?php p(\$l->t( 'Database host' )); ?></label>
#                                <input type="text" name="dbhost" id="dbhost"
#                                        placeholder="<?php p(\$l->t( 'Database host' )); ?>"
#                                        value="localhost"
#                                        autocomplete="off" autocapitalize="none" autocorrect="off">
#                        </p>
#                        <p class="info">
#                                <?php p(\$l->t( 'Please specify the port number along with the host name (e.g., localhost:5432).' )); ?>
#                        </p>
#                </div>
#                </fieldset>
#                <?php endif; ?>
#        <?php endif; ?>
#
#        <?php if(!\$_['dbIsSet'] OR count(\$_['errors']) > 0): ?>
#                <fieldset id="sqliteInformation" class="warning">
#                        <legend><?php p(\$l->t('Performance warning'));?></legend>
#                        <p><?php p(\$l->t('SQLite will be used as database.'));?></p>
#                        <p><?php p(\$l->t('For larger installations we recommend to choose a different database backend.'));?></p>
#                        <p><?php p(\$l->t('Especially when using the desktop client for file syncing the use of SQLite is discouraged.')); ?></p>
#                </fieldset>
#        <?php endif ?>
#
#        <div class="icon-loading-dark float-spinner">&nbsp;</div>
#
#        <div class="buttons"><input type="submit" class="primary" value="<?php p(\$l->t( 'Finish setup' )); ?>" data-finishing="<?php p(\$l->t( 'Finishing �~@�' )); ?>"></div>
#
#        <p class="info">
#                <span class="icon-info-white"></span>
#                <?php p(\$l->t('Need help?'));?>
#                <a target="_blank" rel="noreferrer" href="<?php p(link_to_docs('admin-install')); ?>"><?php p(\$l->t('See the documentation'));?> �~F~W</a>
#        </p>
#</form>
#EOF


}


# ---------------------------------------------------------
# Function to configure Privoxy
# --------------------------------------------------------
configure_privoxy()
{
echo "Configuring Privoxy ..." | tee -a /var/libre_config.log
/etc/init.d/privoxy stop
rm -f /etc/rc?.d/*privoxy*

#Privoxy I2P

cat << EOF > /etc/privoxy/config
user-manual /usr/share/doc/privoxy/user-manual
confdir /etc/privoxy
logdir /var/log/privoxy
actionsfile match-all.action # Actions that are applied to all sites and maybe overruled later on.
actionsfile default.action   # Main actions file
actionsfile user.action      # User customizations
filterfile default.filter
filterfile user.filter      # User customizations
logfile logfile
listen-address  127.0.0.1:8118
toggle  1
enable-remote-toggle  0
enable-remote-http-toggle  0
enable-edit-actions 0
enforce-blocks 0
buffer-limit 4096
enable-proxy-authentication-forwarding 0
forwarded-connect-retries  0
accept-intercepted-requests 0
allow-cgi-request-crunching 0
split-large-forms 0
keep-alive-timeout 5
tolerate-pipelining 1
socket-timeout 300
forward .i2p 127.0.0.1:4444
EOF

#Privoxy TOR

cat << EOF > /etc/privoxy/config-tor 
confdir /etc/privoxy
logdir /var/log/privoxy
actionsfile default.action   # Main actions file
actionsfile user.action      # User customizations
filterfile default.filter
logfile logfile
user-manual /usr/share/doc/privoxy/user-manual
listen-address 127.0.0.1:8119
toggle 0
enable-remote-toggle 0
enable-remote-http-toggle 0
enable-edit-actions 0
forward-socks5t / 127.0.0.1:9050 .
max-client-connections 4096
EOF

cp /etc/init.d/privoxy /etc/init.d/privoxy-tor
sed "s~Provides:.*~Provides:          privoxy-tor~g" -i  /etc/init.d/privoxy-tor
sed "s~PIDFILE=.*~PIDFILE=/var/run/\$NAME-tor.pid~g" -i  /etc/init.d/privoxy-tor
sed "s~CONFIGFILE=.*~CONFIGFILE=/etc/privoxy/config-tor~g" -i /etc/init.d/privoxy-tor
sed "s~SCRIPTNAME=.*~SCRIPTNAME=/etc/init.d/\$NAME-tor~g" -i /etc/init.d/privoxy-tor

update-rc.d privoxy-tor defaults

echo "Restarting privoxy-tor ..." | tee -a /var/libre_config.log
service privoxy-tor restart | tee -a /var/libre_config.log

echo "Restarting privoxy-i2p ..." | tee -a /var/libre_config.log
service privoxy restart | tee -a /var/libre_config.log

}


# ---------------------------------------------------------
# Function to configure tinyproxy
# ---------------------------------------------------------
configure_tinyproxy()
{
	echo "Configuring tinyproxy ..." | tee -a /var/libre_config.log
cat << EOF > /etc/tinyproxy.conf
User nobody
Group nogroup
Port 8888
Listen 127.0.0.1
Timeout 600
DefaultErrorFile "/usr/share/tinyproxy/default.html"
StatFile "/usr/share/tinyproxy/stats.html"
Logfile "/var/log/tinyproxy/tinyproxy.log"
LogLevel Info
PidFile "/var/run/tinyproxy/tinyproxy.pid"
MaxClients 100
MinSpareServers 5
MaxSpareServers 20
StartServers 10
MaxRequestsPerChild 0
Allow 127.0.0.1
ViaProxyName "tinyproxy"
ConnectPort 443
ConnectPort 563
EOF

	# Restarting tinyproxy
	/etc/init.d/tinyproxy restart | tee -a /var/libre_config.log
}


# ---------------------------------------------------------
# Function to configure squid
# ---------------------------------------------------------
configure_squid()
{
echo "Configuring squid server ..." | tee -a /var/libre_config.log

# Generating certificates for ssl connection
echo "Generating certificates ..." | tee -a /var/libre_config.log
if [ ! -e /etc/squid/ssl_cert ]; then
mkdir /etc/squid/ssl_cert
openssl req -new -newkey rsa:2048 -days 365 -nodes -x509  \
-keyout /etc/squid/ssl_cert/squid.key \
-out /etc/squid/ssl_cert/squid.crt -batch | tee -a /var/libre_config.log
chown -R proxy:proxy /etc/squid/ssl_cert
chmod -R 777 /etc/squid/ssl_cert
fi

echo "Creating log directory for Squid..." | tee -a /var/libre_config.log
rm -rf mkdir /var/log/squid | tee -a /var/libre_config.log
mkdir /var/log/squid
chown -R proxy:proxy /var/log/squid
chmod -R 777 /var/log/squid

echo "Calling Squid to create swap directories and initialize cert cache dir..." | tee -a /var/libre_config.log
squid -z | tee -a /var/libre_config.log
if [ -d "/var/cache/squid/ssl_db" ]; then
rm -rf /var/cache/squid/ssl_db
fi
/lib/squid/ssl_crtd -c -s /var/cache/squid/ssl_db
chown -R proxy:proxy /var/cache/squid/ssl_db
chmod -R 777 /var/cache/squid/ssl_db

# squid configuration
echo "Creating squid conf file ..." | tee -a /var/libre_config.log
echo "
acl SSL_ports port 443
acl Safe_ports port 80          # http
acl Safe_ports port 21          # ftp
acl Safe_ports port 443         # https
acl Safe_ports port 70          # gopher
acl Safe_ports port 210         # wais
acl Safe_ports port 1025-65535  # unregistered ports
acl Safe_ports port 280         # http-mgmt
acl Safe_ports port 488         # gss-http
acl Safe_ports port 591         # filemaker
acl Safe_ports port 777         # multiling http
acl CONNECT method CONNECT
acl librenetwork src 10.0.0.0/24
http_access deny !Safe_ports
http_access deny CONNECT !SSL_ports
http_access allow localhost manager
http_access deny manager
http_access allow localhost
http_access allow librenetwork
http_access deny all

# squidGuard configuration
url_rewrite_program /usr/bin/squidGuard -c /etc/squidguard/squidGuard.conf

# http configuration
http_port 10.0.0.1:3130 intercept
coredump_dir /var/spool/squid

# https configuration
https_port 10.0.0.1:3131 intercept ssl-bump generate-host-certificates=on dynamic_cert_mem_cache_size=4MB cert=/etc/squid/ssl_cert/squid.crt key=/etc/squid/ssl_cert/squid.key
always_direct allow all

# SSL Proxy options
ssl_bump server-first all
sslproxy_cert_error allow all
sslproxy_cert_adapt setCommonName ssl::certDomainMismatch
sslproxy_options ALL,SINGLE_DH_USE,NO_SSLv3,NO_SSLv2 

# Refresh patterns
refresh_pattern ^ftp:           1440    20%     10080
refresh_pattern ^gopher:        1440    0%      1440
refresh_pattern -i (/cgi-bin/|\\?) 0     0%      0
refresh_pattern .               0       20%     4320

# sslcrtd configuration
sslcrtd_program /lib/squid/ssl_crtd -s /var/cache/squid/ssl_db -M 4MB
sslcrtd_children 5

# icap configuration
icap_enable on
icap_send_client_ip on
icap_send_client_username on
icap_client_username_encode off
icap_client_username_header X-Authenticated-User
icap_preview_enable on
icap_preview_size 1024
icap_service icap_service_req reqmod_precache bypass=1 icap://127.0.0.1:1344/squidclamav
adaptation_access icap_service_req allow all
icap_service icap_service_resp respmod_precache bypass=1 icap://127.0.0.1:1344/squidclamav
#adaptation_access icap_service_resp allow all

# ecap configuration
loadable_modules /usr/local/lib/libreqmod.so
loadable_modules /usr/local/lib/librespmod.so
ecap_enable on
ecap_service ecap_service_req reqmod_precache bypass=on ecap://filtergizmo.com/ecapguardian/reqmod ecapguardian_listen_socket=/etc/ecapguardian/ecap/reqmod
adaptation_access ecap_service_req allow all
ecap_service ecap_service_resp respmod_precache bypass=on ecap://filtergizmo.com/ecapguardian/respmod ecapguardian_listen_socket=/etc/ecapguardian/ecap/respmod
#adaptation_access ecap_service_resp allow all

adaptation_service_chain myChain ecap_service_resp icap_service_resp
adaptation_access myChain allow all

via off
forwarded_for off

request_header_access From deny all
request_header_access Server deny all
request_header_access WWW-Authenticate deny all
request_header_access Link deny all
request_header_access Cache-Control deny all
request_header_access Proxy-Connection deny all
request_header_access X-Cache deny all
request_header_access X-Cache-Lookup deny all
request_header_access Via deny all
request_header_access X-Forwarded-For deny all
request_header_access Pragma deny all
request_header_access Keep-Alive deny all
" > /etc/squid/squid.conf

echo "Configuring squid startup file ..." | tee -a /var/libre_config.log
if [ ! -e /etc/squid/squid3.rc ]; then
echo "Could not find squid srartup script. Exiting ..." | tee -a /var/libre_config.log
exit 8
else
rm -rf /etc/init.d/squid*
cp /etc/squid/squid3.rc /etc/init.d/squid
sed "s~Provides:.*~Provides:          squid~g" -i  /etc/init.d/squid
sed "s~NAME=.*~NAME=squid~g" -i  /etc/init.d/squid
sed "s~DAEMON=.*~DAEMON=/usr/sbin/squid~g" -i  /etc/init.d/squid
sed "s~PIDFILE=.*~PIDFILE=/var/run/squid.pid~g" \
-i  /etc/init.d/squid
sed "s~CONFIG=.*~CONFIG=/etc/squid/squid.conf~g" \
-i /etc/init.d/squid
chmod +x /etc/init.d/squid
fi

update-rc.d squid start defaults
echo "Restarting squid server ..." | tee -a /var/libre_config.log
service squid restart | tee -a /var/libre_config.log

# squid TOR

echo "Creating squid-tor conf file ..." | tee -a /var/libre_config.log
cat << EOF > /etc/squid/squid-tor.conf 
# Tor acl
acl tor_url dstdomain .onion

# Privoxy+Tor access rules 
never_direct allow tor_url

# Local Privoxy is cache parent 
cache_peer 127.0.0.1 parent 8119 0 no-query no-digest default

cache_peer_access 127.0.0.1 allow tor_url
cache_peer_access 127.0.0.1 deny all

#acl manager proto cache_object
acl localhost src 127.0.0.1/32 
acl to_localhost dst 127.0.0.0/8 0.0.0.0/32 

acl localnet src 10.0.0.0/8     # RFC1918 possible internal network

acl SSL_ports port 443
acl Safe_ports port 80          # http
acl Safe_ports port 21          # ftp
acl Safe_ports port 443         # https
acl Safe_ports port 70          # gopher
acl Safe_ports port 210         # wais
acl Safe_ports port 1025-65535  # unregistered ports
acl Safe_ports port 280         # http-mgmt
acl Safe_ports port 488         # gss-http
acl Safe_ports port 591         # filemaker
acl Safe_ports port 777         # multiling http
acl CONNECT method CONNECT

http_access allow localnet
http_access allow localhost
http_access allow all
http_access deny all

#http_access deny manager

http_access deny !Safe_ports

http_access deny CONNECT !SSL_ports

http_access deny all

http_port 10.0.0.1:3129 accel vhost allow-direct

hierarchy_stoplist cgi-bin ?

never_direct allow all

cache_store_log none

pid_filename /var/run/squid-tor.pid

cache_log /var/log/squid/cache.log

coredump_dir /var/spool/squid

#url_rewrite_program /usr/bin/squidGuard

no_cache deny all

# icap configuration
icap_enable on
icap_send_client_ip on
icap_send_client_username on
icap_client_username_encode off
icap_client_username_header X-Authenticated-User
icap_preview_enable on
icap_preview_size 1024
icap_service service_req reqmod_precache bypass=1 icap://127.0.0.1:1344/squidclamav
adaptation_access service_req allow all
icap_service service_resp respmod_precache bypass=1 icap://127.0.0.1:1344/squidclamav
adaptation_access service_resp allow all
EOF

echo "Configuring squid-tor startup file ..." | tee -a /var/libre_config.log
cp /etc/init.d/squid /etc/init.d/squid-tor
sed "s~Provides:.*~Provides:          squid-tor~g" -i  /etc/init.d/squid-tor
sed "s~PIDFILE=.*~PIDFILE=/var/run/squid-tor.pid~g" -i  /etc/init.d/squid-tor
sed "s~CONFIG=.*~CONFIG=/etc/squid/squid-tor.conf~g" -i /etc/init.d/squid-tor

update-rc.d squid-tor start defaults
echo "Restarting squid-tor ..." | tee -a /var/libre_config.log
service squid-tor restart | tee -a /var/libre_config.log

#Squid I2P

echo "Creating squid-i2p conf file ..." | tee -a /var/libre_config.log
cat << EOF > /etc/squid/squid-i2p.conf
cache_peer 127.0.0.1 parent 8118 7 no-query no-digest

#acl manager proto cache_object
acl localhost src 127.0.0.1/32 
acl to_localhost dst 127.0.0.0/8 0.0.0.0/32 

acl localnet src 10.0.0.0/8     # RFC1918 possible internal network

acl SSL_ports port 443
acl Safe_ports port 80          # http
acl Safe_ports port 21          # ftp
acl Safe_ports port 443         # https
acl Safe_ports port 70          # gopher
acl Safe_ports port 210         # wais
acl Safe_ports port 1025-65535  # unregistered ports
acl Safe_ports port 280         # http-mgmt
acl Safe_ports port 488         # gss-http
acl Safe_ports port 591         # filemaker
acl Safe_ports port 777         # multiling http
acl CONNECT method CONNECT

http_access allow localnet
http_access allow localhost
http_access allow all
http_access deny all

http_access deny manager

http_access deny !Safe_ports

http_access deny CONNECT !SSL_ports

http_access deny all

http_port 10.0.0.1:3128 accel vhost allow-direct

hierarchy_stoplist cgi-bin ?

never_direct allow all

cache_store_log none

pid_filename /var/run/squid-i2p.pid

cache_log /var/log/squid/cache.log

coredump_dir /var/spool/squid

#url_rewrite_program /usr/bin/squidGuard

no_cache deny all

# icap configuration
icap_enable on
icap_send_client_ip on
icap_send_client_username on
icap_client_username_encode off
icap_client_username_header X-Authenticated-User
icap_preview_enable on
icap_preview_size 1024
icap_service service_req reqmod_precache bypass=1 icap://127.0.0.1:1344/squidclamav
adaptation_access service_req allow all
icap_service service_resp respmod_precache bypass=1 icap://127.0.0.1:1344/squidclamav
adaptation_access service_resp allow all
EOF

echo "Configuring squid-i2p startup file ..." | tee -a /var/libre_config.log
cp /etc/init.d/squid /etc/init.d/squid-i2p
sed "s~Provides:.*~Provides:          squid-i2p~g" -i  /etc/init.d/squid-i2p
sed "s~PIDFILE=.*~PIDFILE=/var/run/squid-i2p.pid~g" -i  /etc/init.d/squid-i2p
sed "s~CONFIG=.*~CONFIG=/etc/squid/squid-i2p.conf~g" -i /etc/init.d/squid-i2p

update-rc.d squid-i2p start defaults 
echo "Restarting squid-i2p ..." | tee -a /var/libre_config.log
service squid-i2p restart | tee -a /var/libre_config.log
}


# ---------------------------------------------------------
# Function to configure c-icap
# ---------------------------------------------------------
configure_c_icap()
{
echo "Configuring c-icap ..." | tee -a /var/libre_config.log

# Making c-icap daemon run automatically on startup
echo "
# Defaults for c-icap initscript
# sourced by /etc/init.d/c-icap
# installed at /etc/default/c-icap by the maintainer scripts

# Should c-icap daemon run automatically on startup? (default: no)
START=yes

# Additional options that are passed to the Daemon.
DAEMON_ARGS=\"\"
" > /etc/default/c-icap

# c-icap configuration
echo "
PidFile /var/run/c-icap/c-icap.pid
CommandsSocket /var/run/c-icap/c-icap.ctl
Timeout 300
MaxKeepAliveRequests 100
KeepAliveTimeout 600
StartServers 3
MaxServers 10
MinSpareThreads     10
MaxSpareThreads     20
ThreadsPerChild     10
MaxRequestsPerChild  0
Port 1344
User c-icap
Group c-icap
ServerAdmin admin@librerouter.net
ServerName librerouter
TmpDir /tmp
MaxMemObject 131072
DebugLevel 1
TemplateDir /usr/share/c_icap/templates/
TemplateDefaultLanguage en
LoadMagicFile /etc/c-icap/c-icap.magic
RemoteProxyUsers off
RemoteProxyUserHeader X-Authenticated-User
RemoteProxyUserHeaderEncoded on
ServerLog /var/log/c-icap/server.log
AccessLog /var/log/c-icap/access.log
Service squidclamav squidclamav.so
Service echo srv_echo.so
" > /etc/c-icap/c-icap.conf

# Modules directory in Intel
if [ "$PROCESSOR" = "Intel" ]; then
echo "
ModulesDir /usr/lib/x86_64-linux-gnu/c_icap
ServicesDir /usr/lib/x86_64-linux-gnu/c_icap
" >> /etc/c-icap/c-icap.conf
fi

# Modules directory in ARM
if [ "$PROCESSOR" = "ARM" ]; then
echo "
ModulesDir /usr/lib/arm-linux-gnueabihf/c_icap
ServicesDir /usr/lib/arm-linux-gnueabihf/c_icap
" >> /etc/c-icap/c-icap.conf
fi

echo "Restarting c-icap service ..." | tee -a /var/libre_config.log
service c-icap restart | tee -a /var/libre_config.log
}


# ---------------------------------------------------------
# Function to configure squidclamav
# ---------------------------------------------------------
configure_squidclamav()
{
echo "Configuring squidclamav ..." | tee -a /var/libre_config.log
echo "
maxsize 5000000
redirect http://warning.librerouter.net/virus_warning_page.html
clamd_local /var/run/clamav/clamd.ctl
#clamd_ip 10.0.0.1,127.0.0.1
#clamd_port 3310
timeout 1
logredir 0
dnslookup 1
safebrowsing 0
" > /etc/squidclamav.conf

echo "Restarting clamav daemon ..." | tee -a /var/libre_config.log
service clamav-daemon restart | tee -a /var/libre_config.log
}


# ---------------------------------------------------------
# Function to configure squidguard
# ---------------------------------------------------------
configure_squidguard()
{

echo "Configuring squidguard ..." | tee -a /var/libre_config.log

mkdir -p /etc/squidguard

# log file
touch /var/log/squidguard/squidGuard.log
chmod a+rw /var/log/squidguard/squidGuard.log

# Coniguration file
cat << EOF > /etc/squidguard/squidGuard.conf
#
# CONFIG FILE FOR SQUIDGUARD
#

dbhome /usr/local/squidGuard/db/blacklists
logdir /usr/local/squidGuard/logs

dest ads {
domainlist ads/domains
urllist ads/urls
}

dest proxy {
domainlist proxy/domains
urllist proxy/urls
}

dest spyware {
domainlist spyware/domains
urllist spyware/urls
}

dest redirector {
domainlist redirector/domains
urllist redirector/urls
}

dest suspect {
domainlist suspect/domains
urllist suspect/urls
}

# Access control 
acl {
default {
	pass !ads !proxy !spyware !redirector !suspect all
	redirect http://warning.librerouter.net/squidguard_warning_page.html
}
}
EOF

squidGuard -C all 
chmod -R a+rw /usr/local/squidGuard/db/*
}


# ---------------------------------------------------------
# Function to configure squidguardmgr
# ---------------------------------------------------------
configure_squidguardmgr()
{
# squidguardmgr configuration
cat << EOF > /var/www/squidguardmgr/squidguardmgr.conf
#
# SquidGuard Manager configuration file
#

# Path to the grep system command
GREP    /bin/grep

# Path to the find system command
FIND    /usr/bin/find

# Path to the tail system command
TAIL    /usr/bin/tail

# Path to the diff system command
DIFF    /usr/bin/diff

# Path to the rm system command
RM      /bin/rm

# Path to the SquidGuard program. You can set it to off to disable the
# SquidGuard manager interface and get only the SquidClamav manager.
SQUIDGUARD      /usr/bin/squidGuard

# Path to the SquidGuard configuration file
CONF_FILE       /etc/squidguard/squidGuard.conf

# Path to the SquidClamav program. You can set it to off to disable the
# SquidClamav manager interface and get only the SquidGuard manager.
# If you use SquidClamav v6.x with the c-icap server, set this directive to
# the value: c-icap
SQUIDCLAMAV     off

# Path to the c-icap control socket. Used by SquidClamav Manager to reload
# c-icap server to apply SquidClamav configuration changes. Used only with
# SquidClamav v6.x branch.
C_ICAP_SOCKET

# Path to the SquidClamav configuration file
SC_CONF_FILE

# Used to set the language, default is en_US.
# Current translation are: en_US, fr_FR.
LANG            en_US

# Command to reload Squid. You may use the wrapper as squid
# can only be reload as root. This wrapper will run the command
# /usr/local/squid/sbin/squid -k reconfigure
SQUID_WRAPPER   /var/www/squidguardmgr/squid_wrapper

# SquidGuardMgr URL base where images are stored
IMG_DIR         images

# SquidGuardMgr Style Sheet CSS URL
CSS_FILE        squidguardmgr.css

# SquidGuardMgr Javascript URL
JS_FILE         squidguardmgr.js

# Comma separated list of DNS Blacklists
#DNSBL  your.preferred.blacklist.com,other.preferred.blacklist.com

# Number of last lines displayed from log files
TAIL_LINES      1000

# Keep added/removed items from squidGuard blocklists as diff file
# to be able to recover change after a fresh download of blocklists
KEEP_DIFF       1
EOF
}


# ---------------------------------------------------------
# Function to configure ecapguardian
# ---------------------------------------------------------
configure_ecapguardian()
{

echo "Configuring ecapguardian ..." | tee -a /var/libre_config.log

# Creating user
useradd e2guardian

# Creating log file
touch /var/log/ecapguardian/access.log
chmod a+rw /var/log/ecapguardian/access.log

# Creating socket directory
mkdir -p /etc/ecapguardian/ecap

# Running e2guardian
ecapguardian &

# Setting sockets permissions 
chmod -R a+rw /etc/ecapguardian/ecap

# Phrase config
sed "s/phrasefiltermode = 2/phrasefiltermode = 3/g" -i /etc/ecapguardian/ecapguardian.conf

# Preparing files 
rm -rf /root/libre_scripts/ecapguardian.sh
mkdir -p /root/libre_scripts/
touch /root/libre_scripts/ecapguardian.sh
chmod +x /root/libre_scripts/ecapguardian.sh

cat << EOF > /root/libre_scripts/ecapguardian.sh
#!/bin/bash
sleep 60
/usr/sbin/ecapguardian &
sleep 30
chmod -R a+rwx /etc/ecapguardian/ecap
EOF

# Creating cron job
rm -rf /root/libre_scripts/cron_jobs
echo "@reboot /root/libre_scripts/ecapguardian.sh" > /root/libre_scripts/cron_jobs
crontab /root/libre_scripts/cron_jobs
}


# ---------------------------------------------------------
# Function to configure postfix mail service
# ---------------------------------------------------------
configure_postfix()
{
# Configurinf postfix mail service
echo "Configuring postfix ..." | tee -a /var/libre_config.log

# Creating vmail user
useradd -r -u 150 -g mail -d /var/vmail -s /sbin/nologin -c "Virtual MailDir Handler" vmail
mkdir -p /var/vmail
chown vmail:mail /var/vmail
chmod 770 /var/vmail

cat << EOF > /etc/postfix/mysql_virtual_alias_domainaliases_maps.cf
user = root 
password = $MYSQL_PASS 
hosts = 127.0.0.1 
dbname = mail 
query = SELECT goto FROM alias,alias_domain WHERE alias_domain.alias_domain = '%d' AND alias.address=concat('%u', '@', alias_domain.target_domain) AND alias.active = 1
EOF

cat << EOF > /etc/postfix/mysql_virtual_alias_maps.cf
user = root
password = $MYSQL_PASS
hosts = 127.0.0.1
dbname = mail
table = alias
select_field = goto
where_field = address
additional_conditions = and active = '1'
EOF

cat << EOF > /etc/postfix/mysql_virtual_domains_maps.cf
user = root
password = $MYSQL_PASS
hosts = 127.0.0.1
dbname = mail
table = domain
select_field = domain
where_field = domain
additional_conditions = and backupmx = '0' and active = '1'
EOF

cat << EOF > /etc/postfix/mysql_virtual_mailbox_domainaliases_maps.cf
user = root
password = $MYSQL_PASS
hosts = 127.0.0.1
dbname = mail
query = SELECT maildir FROM mailbox, alias_domain
  WHERE alias_domain.alias_domain = '%d'
  AND mailbox.username=concat('%u', '@', alias_domain.target_domain )
  AND mailbox.active = 1
EOF

cat << EOF > /etc/postfix/mysql_virtual_mailbox_maps.cf
user = root
password = $MYSQL_PASS
hosts = 127.0.0.1
dbname = mail
table = mailbox
select_field = CONCAT(domain, '/', local_part)
where_field = username
additional_conditions = and active = '1'
EOF

cat << EOF > /etc/postfix/header_checks
/^Received:/                 IGNORE
/^User-Agent:/               IGNORE
/^X-Mailer:/                 IGNORE
/^X-Originating-IP:/         IGNORE
/^x-cr-[a-z]*:/              IGNORE
/^Thread-Index:/             IGNORE
EOF

cat << EOF > /etc/postfix/main.cf
smtpd_banner = \$myhostname ESMTP \$mail_name
biff = no
append_dot_mydomain = no
readme_directory = no
smtpd_sasl_type = dovecot
smtpd_sasl_path = private/auth
smtpd_sasl_auth_enable = yes
broken_sasl_auth_clients = yes
smtpd_sasl_security_options = noanonymous
smtpd_sasl_local_domain =
smtpd_sasl_authenticated_header = yes
smtpd_tls_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem
smtpd_tls_key_file=/etc/ssl/private/ssl-cert-snakeoil.key
smtp_tls_note_starttls_offer = yes
smtpd_tls_loglevel = 1
smtpd_tls_received_header = yes
smtpd_tls_session_cache_timeout = 3600s
tls_random_source = dev:/dev/urandom
smtpd_use_tls = yes
smtpd_enforce_tls = no
smtp_use_tls = yes
smtp_enforce_tls = no
smtpd_tls_security_level = may
smtp_tls_security_level = may
unknown_local_recipient_reject_code = 450
maximal_queue_lifetime = 7d
minimal_backoff_time = 1000s
maximal_backoff_time = 8000s
smtp_helo_timeout = 60s
smtpd_recipient_limit = 16
smtpd_soft_error_limit = 3
smtpd_hard_error_limit = 12
smtpd_helo_restrictions = permit_mynetworks, warn_if_reject reject_non_fqdn_hostname, reject_invalid_hostname, permit
smtpd_sender_restrictions = permit_sasl_authenticated, permit_mynetworks, warn_if_reject reject_non_fqdn_sender, reject_unknown_sender_domain, reject_unauth_pipelining, permit
smtpd_client_restrictions = reject_rbl_client b.barracudacentral.org, reject_rbl_client zen.spamhaus.org, reject_rbl_client spam.dnsbl.sorbs.net
smtpd_recipient_restrictions = reject_unauth_pipelining, permit_mynetworks, permit_sasl_authenticated, reject_non_fqdn_recipient, reject_unknown_recipient_domain, reject_unauth_destination, check_policy_service inet:127.0.0.1:10023, permit
smtpd_data_restrictions = reject_unauth_pipelining
smtpd_relay_restrictions = reject_unauth_pipelining, permit_mynetworks, permit_sasl_authenticated, reject_non_fqdn_recipient, reject_unknown_recipient_domain, reject_unauth_destination, check_policy_service inet:127.0.0.1:10023, permit
smtpd_helo_required = yes
smtpd_delay_reject = yes
disable_vrfy_command = yes
myhostname = librerouter
myorigin = /etc/mailname
mydestination =
mynetworks = 10.0.0.0/24 127.0.0.0/8 
mailbox_size_limit = 0
recipient_delimiter = +
inet_interfaces = all
mynetworks_style = host
virtual_mailbox_base = /var/vmail
virtual_mailbox_maps = mysql:/etc/postfix/mysql_virtual_mailbox_maps.cf, mysql:/etc/postfix/mysql_virtual_mailbox_domainaliases_maps.cf
virtual_uid_maps = static:150
virtual_gid_maps = static:8
virtual_alias_maps = mysql:/etc/postfix/mysql_virtual_alias_maps.cf, mysql:/etc/postfix/mysql_virtual_alias_domainaliases_maps.cf
virtual_mailbox_domains = mysql:/etc/postfix/mysql_virtual_domains_maps.cf
virtual_transport = dovecot
dovecot_destination_recipient_limit = 1
header_checks = regexp:/etc/postfix/header_checks
enable_original_recipient = no
EOF

cat << EOF > /etc/postfix/master.cf
smtp      inet  n       -       -       -       -       smtpd
submission inet n       -       -       -       -       smtpd
  -o syslog_name=postfix/submission
  -o smtpd_tls_security_level=encrypt
  -o smtpd_sasl_auth_enable=yes
  -o smtpd_enforce_tls=yes
  -o smtpd_client_restrictions=permit_sasl_authenticated,reject_unauth_destination,reject
  -o smtpd_sasl_tls_security_options=noanonymous
smtps     inet  n       -       -       -       -       smtpd
  -o syslog_name=postfix/smtps
  -o smtpd_tls_wrappermode=yes
  -o smtpd_sasl_auth_enable=yes
  -o smtpd_tls_auth_only=yes
  -o smtpd_client_restrictions=permit_sasl_authenticated,reject_unauth_destination,reject
  -o smtpd_sasl_security_options=noanonymous,noplaintext
  -o smtpd_sasl_tls_security_options=noanonymous
pickup    fifo  n       -       -       60      1       pickup
  -o content_filter=
  -o receive_override_options=no_header_body_checks
cleanup   unix  n       -       -       -       0       cleanup
qmgr      fifo  n       -       n       300     1       qmgr
tlsmgr    unix  -       -       -       1000?   1       tlsmgr
rewrite   unix  -       -       -       -       -       trivial-rewrite
bounce    unix  -       -       -       -       0       bounce
defer     unix  -       -       -       -       0       bounce
trace     unix  -       -       -       -       0       bounce
verify    unix  -       -       -       -       1       verify
flush     unix  n       -       -       1000?   0       flush
proxymap  unix  -       -       n       -       -       proxymap
proxywrite unix -       -       n       -       1       proxymap
smtp      unix  -       -       -       -       -       smtp
relay     unix  -       -       -       -       -       smtp
showq     unix  n       -       -       -       -       showq
error     unix  -       -       -       -       -       error
retry     unix  -       -       -       -       -       error
discard   unix  -       -       -       -       -       discard
local     unix  -       n       n       -       -       local
virtual   unix  -       n       n       -       -       virtual
lmtp      unix  -       -       -       -       -       lmtp
anvil     unix  -       -       -       -       1       anvil
scache    unix  -       -       -       -       1       scache
maildrop  unix  -       n       n       -       -       pipe
  flags=DRhu user=vmail argv=/usr/bin/maildrop -d \${recipient}
uucp      unix  -       n       n       -       -       pipe
  flags=Fqhu user=uucp argv=uux -r -n -z -a\$sender - $nexthop!rmail (\$recipient)
ifmail    unix  -       n       n       -       -       pipe
  flags=F user=ftn argv=/usr/lib/ifmail/ifmail -r \$nexthop (\$recipient)
bsmtp     unix  -       n       n       -       -       pipe
  flags=Fq. user=bsmtp argv=/usr/lib/bsmtp/bsmtp -t\$nexthop -f\$sender \$recipient
scalemail-backend unix  -       n       n       -       2       pipe
  flags=R user=scalemail argv=/usr/lib/scalemail/bin/scalemail-store \${nexthop} \${user} \${extension}
mailman   unix  -       n       n       -       -       pipe
  flags=FR user=list argv=/usr/lib/mailman/bin/postfix-to-mailman.py
  \${nexthop} \${user}

# The next two entries integrate with Amavis for anti-virus/spam checks.
#amavis      unix    -       -       -       -       3       smtp
#  -o smtp_data_done_timeout=1200
#  -o smtp_send_xforward_command=yes
#  -o disable_dns_lookups=yes
#  -o max_use=20
#127.0.0.1:10025 inet    n       -       -       -       -       smtpd
#  -o content_filter=
#  -o local_recipient_maps=
#  -o relay_recipient_maps=
#  -o smtpd_restriction_classes=
#  -o smtpd_delay_reject=no
#  -o smtpd_client_restrictions=permit_mynetworks,reject
#  -o smtpd_helo_restrictions=
#  -o smtpd_sender_restrictions=
#  -o smtpd_recipient_restrictions=permit_mynetworks,reject
#  -o smtpd_data_restrictions=reject_unauth_pipelining
#  -o smtpd_end_of_data_restrictions=
#  -o mynetworks=127.0.0.0/8
#  -o smtpd_error_sleep_time=0
#  -o smtpd_soft_error_limit=1001
#  -o smtpd_hard_error_limit=1000
#  -o smtpd_client_connection_count_limit=0
#  -o smtpd_client_connection_rate_limit=0
#  -o receive_override_options=no_header_body_checks,no_unknown_recipient_checks

# Integration with Dovecot - hand mail over to it for local delivery, and
# run the process under the vmail user and mail group.
dovecot      unix   -        n      n       -       -   pipe
  flags=DRhu user=vmail:mail argv=/usr/lib/dovecot/dovecot-lda -d \$(recipient)
EOF

echo "librerouter.net" > /etc/mailname
echo "Restarting postfix ..." | tee -a /var/libre_config.log
service postfix restart | tee -a /var/libre_config.log
}


# ---------------------------------------------------------
# Function to configure postfixadmin service
# ---------------------------------------------------------
configure_postfixadmin()
{
echo "Configuring postfixadmin ..." | tee -a /var/libre_config.log

# Creating database
echo "Configuring postfixadmin database ..."
rm -r /var/lib/mysql/mail
if [ ! -e  /var/lib/mysql/mail ]; then
	MYSQL_USER="root"

	# Creating MySQL database frnd for friendica local service
echo "CREATE DATABASE mail;" \
| mysql -u "$MYSQL_USER" -p"$MYSQL_PASS"

# Inserting database scheme
mysql -u "$MYSQL_USER" -p"$MYSQL_PASS" mail < postfixadmin.txt

	# Geneerating admin password
POSTFIX_PASS=`pwgen 10 1`
POSTFIX_PASS_ENCRYPT=`openssl passwd -1 $POSTFIX_PASS`

	# Inserting admin info
echo "insert into admin (username, password, created, modified, active ) values ('admin', '$POSTFIX_PASS_ENCRYPT', '0000-00-00 00:00:00', '0000-00-00 00:00:00', '1')" |  mysql -u root -p"$MYSQL_PASS" mail        
fi
echo "insert into domain_admins (username, domain, created, active) values ('admin', 'ALL', '0000-00-00 00:00:00', '1')" | mysql -u root -p"$MYSQL_PASS" mail
echo "insert into domain (domain, description, aliases, mailboxes, maxquota, quota, transport, backupmx, created, modified, active) values ('ALL', '', '0', '0', '0', '0', '', '0', '0000-00-00 00:00:00', '0000-00-00 00:00:00', '1')" | mysql -u root -p"$MYSQL_PASS" mail

cat << EOF > /etc/postfixadmin/config.inc.php
<?php
require_once('dbconfig.inc.php');
if (!isset(\$dbserver) || empty(\$dbserver))
        \$dbserver='localhost';
\$CONF['configured'] = true;
\$CONF['setup_password'] = '3d1d32f945b221962d34ccd2306f32a9:8f5e399cd4462b51f88f91c7cb4c79c731b0b659';
\$CONF['postfix_admin_url'] = '/postfixadmin';
\$CONF['postfix_admin_path'] = dirname(__FILE__);
\$CONF['default_language'] = 'en';
\$CONF['database_type'] = 'mysqli';
\$CONF['database_host'] = 'localhost';
\$CONF['database_user'] = 'root';
\$CONF['database_password'] = '$MYSQL_PASS';
\$CONF['database_name'] = 'mail';
\$CONF['database_prefix'] = '';
\$CONF['database_tables'] = array (
    'admin' => 'admin',
    'alias' => 'alias',
    'alias_domain' => 'alias_domain',
    'config' => 'config',
    'domain' => 'domain',
    'domain_admins' => 'domain_admins',
    'fetchmail' => 'fetchmail',
    'log' => 'log',
    'mailbox' => 'mailbox',
    'vacation' => 'vacation',
    'vacation_notification' => 'vacation_notification',
    'quota' => 'quota',
    'quota2' => 'quota2',
);
\$CONF['admin_email'] = 'admin@librerouter.net';
\$CONF['smtp_server'] = 'localhost';
\$CONF['smtp_port'] = '25';
\$CONF['encrypt'] = 'md5crypt';
\$CONF['authlib_default_flavor'] = 'md5raw';
\$CONF['dovecotpw'] = "/usr/bin/doveadm pw";
\$CONF['min_password_length'] = 5;
\$CONF['generate_password'] = 'NO';
\$CONF['show_password'] = 'NO';
\$CONF['page_size'] = '10';
\$CONF['default_aliases'] = array (
    'abuse' => 'abuse@change-this-to-your.domain.tld',
    'hostmaster' => 'hostmaster@change-this-to-your.domain.tld',
    'postmaster' => 'postmaster@change-this-to-your.domain.tld',
    'webmaster' => 'webmaster@change-this-to-your.domain.tld'
);
\$CONF['domain_path'] = 'NO';
\$CONF['domain_in_mailbox'] = 'YES';
\$CONF['maildir_name_hook'] = 'NO';
\$CONF['aliases'] = '10';
\$CONF['mailboxes'] = '10';
\$CONF['maxquota'] = '10';
\$CONF['quota'] = 'NO';
\$CONF['quota_multiplier'] = '1024000';
\$CONF['transport'] = 'NO';
\$CONF['transport_options'] = array (
    'virtual',  // for virtual accounts
    'local',    // for system accounts
    'relay'     // for backup mx
);
\$CONF['transport_default'] = 'virtual';
\$CONF['vacation'] = 'NO';
\$CONF['vacation_domain'] = 'autoreply.change-this-to-your.domain.tld';
\$CONF['vacation_control'] ='YES';
\$CONF['vacation_control_admin'] = 'YES';
\$CONF['alias_control'] = 'NO';
\$CONF['alias_control_admin'] = 'NO';
\$CONF['special_alias_control'] = 'NO';
\$CONF['alias_goto_limit'] = '0';
\$CONF['alias_domain'] = 'YES';
\$CONF['backup'] = 'YES';
\$CONF['sendmail'] = 'YES';
\$CONF['logging'] = 'YES';
\$CONF['fetchmail'] = 'YES';
\$CONF['fetchmail_extra_options'] = 'NO';
\$CONF['show_header_text'] = 'NO';
\$CONF['header_text'] = ':: Postfix Admin ::';
\$CONF['user_footer_link'] = "http://change-this-to-your.domain.tld/main";
\$CONF['show_footer_text'] = 'YES';
\$CONF['footer_text'] = 'Return to change-this-to-your.domain.tld';
\$CONF['footer_link'] = 'http://change-this-to-your.domain.tld';
\$CONF['welcome_text'] = <<<EOM
Hi,

Welcome to your new account.
EOM;
\$CONF['emailcheck_resolve_domain']='YES';
\$CONF['show_status']='NO';
\$CONF['show_status_key']='NO';
\$CONF['show_status_text']='&nbsp;&nbsp;';
\$CONF['show_undeliverable']='NO';
\$CONF['show_undeliverable_color']='tomato';
\$CONF['show_undeliverable_exceptions']=array("unixmail.domain.ext","exchangeserver.domain.ext","gmail.com");
\$CONF['show_popimap']='NO';
\$CONF['show_popimap_color']='darkgrey';
\$CONF['show_custom_domains']=array("subdomain.domain.ext","domain2.ext");
\$CONF['show_custom_colors']=array("lightgreen","lightblue");
\$CONF['recipient_delimiter'] = "";
\$CONF['create_mailbox_subdirs_prefix']='INBOX.';
\$CONF['used_quotas'] = 'NO';
\$CONF['new_quota_table'] = 'NO';
\$CONF['theme_logo'] = 'images/logo-default.png';
\$CONF['theme_css'] = 'css/default.css';
\$CONF['xmlrpc_enabled'] = false;
if (file_exists(dirname(__FILE__) . '/config.local.php')) {
    include(dirname(__FILE__) . '/config.local.php');
}
EOF
}


# ---------------------------------------------------------
# Function to configure dovecot
# ---------------------------------------------------------
configure_dovecot()
{
echo "Configuring dovecot ..." | tee -a /var/libre_config.log

# Database Config
cat << EOF > /etc/dovecot/conf.d/auth-sql.conf.ext
passdb {
  driver = sql
  args = /etc/dovecot/dovecot-sql.conf.ext
}
userdb {
  driver = sql
  args = /etc/dovecot/dovecot-sql.conf.ext
}
EOF

cat << EOF >/etc/dovecot/dovecot-sql.conf.ext
driver = mysql
connect = host=localhost dbname=mail user=root password=$MYSQL_PASS
default_pass_scheme = MD5-CRYPT
password_query = \
  SELECT username as user, password, '/var/vmail/%d/%n' as userdb_home, \
  'maildir:/var/vmail/%d/%n' as userdb_mail, 150 as userdb_uid, 8 as userdb_gid \
  FROM mailbox WHERE username = '%u' AND active = '1'
user_query = \
  SELECT '/var/vmail/%d/%n' as home, 'maildir:/var/vmail/%d/%n' as mail, \
  150 AS uid, 8 AS gid, concat('dirsize:storage=', quota) AS quota \
  FROM mailbox WHERE username = '%u' AND active = '1'
EOF

# Authentification Config
cat << EOF > /etc/dovecot/conf.d/10-auth.conf
disable_plaintext_auth = yes
auth_mechanisms = plain login
!include auth-sql.conf.ext
EOF

# Mail Config
cat << EOF > /etc/dovecot/conf.d/10-mail.conf
mail_location = maildir:/var/vmail/%d/%n
mail_uid = vmail
mail_gid = mail
first_valid_uid = 150
last_valid_uid = 150
namespace inbox {
  inbox = yes
}
EOF

# Master Config
cat << EOF > /etc/dovecot/conf.d/10-master.conf
service imap-login {
  inet_listener imap {
  }
  inet_listener imaps {
  }
}
service pop3-login {
  inet_listener pop3 {
  }
  inet_listener pop3s {
  }
}
service lmtp {
  unix_listener lmtp {
  }

}
service imap {
}
service pop3 {
}
service auth {
  unix_listener auth-userdb {
        mode = 0600
        user = vmail
        group = mail
      }
      # Postfix smtp-auth
  unix_listener /var/spool/postfix/private/auth {
        mode = 0660
        user = postfix
        group = postfix
      }
}
service auth-worker {
}
service dict {
  unix_listener dict {
  }
}
EOF

# LDA Config
cat << EOF > /etc/dovecot/conf.d/15-lda.conf
postmaster_address = admin@librerouter.net
protocol lda {
}
EOF

# Setting permissions
chown -R vmail:dovecot /etc/dovecot
chmod -R o-rwx /etc/dovecot

# Setting listen IP address
sed -i 's/#listen = \*, ::/listen = 127.0.0.1/g' /etc/dovecot/dovecot.conf

# Restarting dovecot
echo "Restarting dovecot ..." | tee -a /var/libre_config.log
/etc/init.d/dovecot restart | tee -a /var/libre_config.log
}


# ---------------------------------------------------------
# Function to configure amavis server
# ---------------------------------------------------------             
configure_amavis()
{
echo "Configureing amavis ..." | tee -a /var/libre_config.log
cat << EOF > /etc/amavis/conf.d/15-content_filter_mode
use strict;
@bypass_virus_checks_maps = (
   \\%bypass_virus_checks, \\@bypass_virus_checks_acl, \\\$bypass_virus_checks_re);
@bypass_spam_checks_maps = (
   \\%bypass_spam_checks, \\@bypass_spam_checks_acl, \\\$bypass_spam_checks_re);
1;  # ensure a defined return
EOF

# Database Config
cat << EOF > /etc/amavis/conf.d/50-user
use strict;
\$max_servers  = 3;
\$sa_tag_level_deflt  = -9999;
@lookup_sql_dsn = (
    ['DBI:mysql:database=mail;host=127.0.0.1;port=3306',
     'mail',
     '$MYSQL_PASS']);
\$sql_select_policy = 'SELECT domain from domain WHERE CONCAT("@",domain) IN (%k)';
1;  # ensure a defined return
EOF

# Restarting amavis service
echo "Restarting amavis ..." | tee -a /var/libre_config.log
/etc/init.d/amavis restart | tee -a /var/libre_config.log
}


# ---------------------------------------------------------
# Function to configure spamassasin service
# ---------------------------------------------------------
configure_spamassasin()
{
echo "Configuring spamassasin ..." | tee -a /var/libre_config.log
cat << EOF > /etc/default/spamassassin
ENABLED=1
OPTIONS="--create-prefs --max-children 5 --helper-home-dir"
PIDFILE="/var/run/spamd.pid"
CRON=1
EOF

# Restarting spamassasin
echo "Restarting spamassasin ..." | tee -a /var/libre_config.log
/etc/init.d/spamassassin restart | tee -a /var/libre_config.log
}


# ---------------------------------------------------------
# Function to configure Roundcube service
# ---------------------------------------------------------
configure_roundcube()
{
echo "Configuring roundcube ..." | tee -a /var/libre_config.log
cat << EOF > /etc/roundcube/config.inc.php
<?php
\$config = array();
include_once("/etc/roundcube/debian-db-roundcube.php");
\$config['default_host'] = '10.0.0.1';
\$config['smtp_server'] = '127.0.0.1';
\$config['smtp_port'] = 25;
\$config['smtp_user'] = '';
\$config['smtp_pass'] = '';
\$config['support_url'] = '';
\$config['product_name'] = 'Roundcube Webmail';
\$config['des_key'] = 'WVklLBODesUSZUN4XPwfQMzt';
\$config['plugins'] = array(
'archive',
'zipdownload',
);
\$config['skin'] = 'larry';
EOF
}


# ---------------------------------------------------------
# Function to configura trac server
# ---------------------------------------------------------
configure_trac() 
{
# trac can only be installed on x86_64 (64 bit) architecture
# So we configure it if architecture is x86_64
if [ "$ARCH" == "x86_64" ]; then
        echo "Configuring Trac ..." | tee -a /var/libre_config.log
	rm -rf /opt/trac/libretrac
        mkdir -p /opt/trac/libretrac

        # Initializing trac project
        trac-admin /opt/trac/libretrac initenv LibreProject sqlite:db
	if [ $? -ne 0 ]; then
        	echo "Unable to configure trac. Exiting ..."
       		exit 1
	fi
	   
        # Setting permissions
        chown -R www-data:www-data /opt/trac/libretrac

	export LC_ALL=en_US.UTF-8
	kill -9 `netstat -tulpn | grep 8000 | awk '{print $7}' | awk -F/ '{print $1}'` 2> /dev/null	

	# Creating password file
	touch /opt/trac/libretrac/conf/passwd

	# generating passowrd
	user=admin
	realm=librerouter
	TRAC_PASS=`pwgen 10 1`
        (echo -n "$user:$realm:" && echo -n "$user:$realm:$TRAC_PASS" | md5sum | awk '{print $1}' ) > /opt/trac/libretrac/conf/passwd

	# Set trac admin account
	trac-admin /opt/trac/libretrac permission add admin TRAC_ADMIN 

	# Run trac service
        tracd -s -b 127.0.0.1 --port 8000 --auth="*,/opt/trac/libretrac/conf/passwd,librerouter" /opt/trac/libretrac &
else

        echo "Trac configuration is skipped as detected architecture: $ARCH" | tee -a /var/libre_config.log
fi
}


# ---------------------------------------------------------
# Function to configure redmine
# ---------------------------------------------------------
configure_redmine()
{
        echo "Configuring redmine ..." | tee -a /var/libre_config.log

        # Preparing MySQL
        MYSQL_USER="root"
	echo "CREATE DATABASE redmine CHARACTER SET utf8;" \
	| mysql -u "$MYSQL_USER" -p"$MYSQL_PASS" > /dev/null 2>&1
        #CREATE USER 'redmine'@'localhost' IDENTIFIED BY 'my_password';
        #GRANT ALL PRIVILEGES ON redmine.* TO 'redmine'@'localhost';
        #exit

        # Redmine DB configuration
        cd /opt/redmine/redmine-3.3.1
        cp config/database.yml.example config/database.yml
	cp config/configuration.yml.example config/configuration.yml

	# Run bundle
	bundle install --without development test rmagick

        # Customize DB configuration
echo "
production:
  adapter: mysql2
  database: redmine
  host: localhost
  username: root
  password: "$MYSQL_PASS"
  encoding: utf8

#development:
#  adapter: mysql2
#  database: redmine
#  host: localhost
#  username: root
#  password: "$MYSQL_PASS"
#  encoding: utf8
" > config/database.yml

	# Migrate database and load default settings
	RAILS_ENV=production bundle exec rake db:migrate
	RAILS_ENV=production REDMINE_LANG=en bundle exec rake redmine:load_default_data

        # Link the redmine public dir to the apache-redmine root:
        ln -s /opt/redmine/redmine-3.3.1/public/ /var/www/redmine

        # Set permission for Gemfile
        chmod 777 /opt/redmine/redmine-3.3.1/Gemfile.lock
}


# ---------------------------------------------------------
# Function to configure webmin
# ---------------------------------------------------------
configure_webmin()
{
        echo "configuring webmin ..." | tee -a /var/libre_config.log  

        # Disabling ssl in webmin config
        sed -i "s/ssl=1/ssl=0/" /etc/webmin/miniserv.conf

        # Disabling ipv6 in webmin config
        sed 's/ipv6=1/ipv6=0/g' -i /etc/webmin/miniserv.conf

	# Configure webmin to refer webmin.librerouter.net
        if ! grep "webmin.librerouter.net" /etc/webmin/config 2>&1 > /dev/null; then
           echo "referers=webmin.librerouter.net" >> /etc/webmin/config
        fi

        # Restarting webmin server
        /etc/webmin/stop
        /etc/webmin/start

}


# ---------------------------------------------------------
# Function to configure ntop
# ---------------------------------------------------------
configure_ntopng()
{
	echo "configuring ntopng ..." | tee -a /var/libre_config.log

	# Interface configuretion
	# sed -i 's/INTERFACES="none"/INTERFACES="$EXT_INTERFACE"/g' /var/lib/ntop/init.cfg

cat << EOF > /etc/default/ntopng
# In order to disable ntopng use the approriate systemd or sysv tools.

# Space-separated list of interface ntopng should listen on. If empty ntopng
# will try to auto-detect the best interface.
INTERFACES=""

# Port on which ntopng will listen for the web-UI.
HTTP_PORT=3030

# Additional command-line arguments for ntopng.
ADD_ARGS=""
EOF

	# Creating configuration file
	rm -rf /etc/ntopng/ntopng.conf
	mkdir -p /etc/ntopng/
	touch /etc/ntopng/ntopng.conf
	echo "
#--user ntop
#--daemon
#--db-file-path /usr/share/ntop
#--interface $EXT_INTERFACE
#-p /etc/ntop/protocol.list 
#? --protocols=\"HTTP=http|www|https|3128,FTP=ftp|ftp-data\"
#--trace-level 0 # FATALERROR only
#--trace-level 1 # ERROR and above only 
#--trace-level 2 # WARNING and above only
#--trace-level 3 # INFO, WARNING and ERRORs - the default
#--trace-level 4 # NOISY - everything
#--trace-level 6 # NOISY + MSGID
#--trace-level 7 # NOISY + MSGID + file/line
#--daemon --use-syslog
--http-server -w 127.0.0.1:3030
#--https-server -w 127.0.0.1:3001
--pid-path=/var/tmp/ntopng.pid
--daemon
--interface=$EXT_INTERFACE,$INT_INTERFACE
#--http-port=3030
--local-networks="10.0.0.0/24"
--dns-mode=1
--data-dir=/var/tmp/ntopng
--disable-autologout
--community
" > /etc/ntopng/ntopng.conf

# Add dependency on redis-server to ntopng startup files to eliminate
# ocasional startup failures
if ! grep -q '^# Required-Start:.*redis-server' /etc/init.d/ntopng; then
	sed -i 's/^\(# Required-Start:.*\)$/\1 redis-server/' /etc/init.d/ntopng
fi
if ! grep -q '^# Required-Stop:.*redis-server' /etc/init.d/ntopng; then
	sed -i 's/^\(# Required-Stop:.*\) *$/\1 redis-server/' /etc/init.d/ntopng
fi
if ! grep -q '^After=.*redis-server.service' /lib/systemd/system/ntopng.service; then
	sed -i 's/^\(After=.*\)$/\1 redis-server.service/' /lib/systemd/system/ntopng.service
fi

	# Restarting ntopng sevice
	echo "Restarting ntopng ..." | tee -a /var/libre_config.log
	/etc/init.d/ntopng restart | tee -a /var/libre_config.log
}


# ---------------------------------------------------------
# Function to configure redsocks proxy server
# ---------------------------------------------------------
configure_redsocks()
{
        echo "Configuring redsocks ..." | tee -a /var/libre_config.log

        # Creating log file
        rm -rf /var/log/redsocks.log
        touch /var/log/redsocks.log

        # Creating configuretion file
cat << EOF > /opt/redsocks/redsocks.conf
	base {
       		log_debug = off;
        	log_info = on;
        	log = "file:/var/log/redsocks.log";
        	daemon = on;
        	redirector = iptables;
	}
	redsocks {
        	local_ip = 0.0.0.0;
        	local_port = 9051;
        	ip = 127.0.0.1;
        	port = 9050;
        	type = socks5;
	}
EOF
}


# ---------------------------------------------------------
# Configure prosody xmpp server
# ---------------------------------------------------------
configure_prosody()
{
	echo "configuring prosody ..." | tee -a /var/libre_config.log
	if ! cat /etc/prosody/prosody.cfg.lua | grep "interfaces = { \"127.0.0.1\" }"; then
		sed -i '18iinterfaces = { "127.0.0.1" }' /etc/prosody/prosody.cfg.lua 
	fi
	
	# Restarting prosody
	echo "Restarting prosody ..." | tee -a /var/libre_config.log
	/etc/init.d/prosody restart | tee -a /var/libre_config.log
}


# ---------------------------------------------------------
# Configure tomcat server
# ---------------------------------------------------------
configure_tomcat()
{
        echo "configuring tomcat ..." | tee -a /var/libre_config.log
        if ! cat /etc/tomcat7/server.xml | grep "address=\"127.0.0.1\""; then
		sed -i 's/<Connector port="8080" protocol="HTTP\/1.1"/<Connector address="127.0.0.1" port="8080" protocol="HTTP\/1.1"/g' /etc/tomcat7/server.xml
        fi

        # Restarting tomcat
	echo "Restarting tomcat ..." | tee -a /var/libre_config.log
        /etc/init.d/tomcat7 restart | tee -a /var/libre_config.log
}


# ---------------------------------------------------------
# Function to start mailpile local service
# ---------------------------------------------------------
configure_mailpile()
{
echo "Configuring Mailpile local service ..." | tee -a /var/libre_config.log
export MAILPILE_HOME=.local/share/Mailpile
if [ -e $MAILPIEL_HOME/default/mailpile.cfg ]; then
echo "Configuration file does not exist. Exiting ..." | tee -a /var/libre_config.log
exit 6
fi

# Make Mailpile a service with upstart
echo "
description \"Mailpile Webmail Client\"
author      \"Sharon Campbell\"

start on filesystem or runlevel [2345]
stop on shutdown

script

echo \$\$ > /var/run/mailpile.pid
exec /usr/bin/screen -dmS mailpile_init /var/Mailpile/mp

end script

pre-start script
echo \"[\`date\`] Mailpile Starting\" >> /var/log/mailpile.log
end script

pre-stop script
rm /var/run/mailpile.pid
echo \"[\`date\`] Mailpile Stopping\" >> /var/log/mailpile.log
end script
" > /etc/init/mailpile.conf

echo "Starting Mailpile local service ..." | tee -a /var/libre_config.log
/usr/bin/screen -dmS mailpile_init /opt/Mailpile/mp | tee -a /var/libre_config.log
}


# ---------------------------------------------------------
# Function to configure modsecurity
# ---------------------------------------------------------
configure_modsecurity()
{
echo "Configuring modsecurity ..." | tee -a /var/libre_config.log
sudo mv /etc/modsecurity/modsecurity.conf-recommended /etc/modsecurity/modsecurity.conf
sudo sed -i "s/SecRuleEngine DetectionOnly/SecRuleEngine On/" /etc/modsecurity/modsecurity.conf
sudo sed -i "s/SecResponseBodyAccess On/SecResponseBodyAccess Off/" /etc/modsecurity/modsecurity.conf

sudo sed -i "s/SecAuditEngine.*/SecAuditEngine RelevantOnly/" /etc/modsecurity/modsecurity.conf
sudo sed -i "s/SecAuditLogRelevantStatus.*/SecAuditLogRelevantStatus \"^(?:5|4(?!04))\"/" /etc/modsecurity/modsecurity.conf
sudo sed -i "s/SecAuditLogParts.*/SecAuditLogParts ABIDEFGHZ/" /etc/modsecurity/modsecurity.conf
sudo sed -i "s/SecAuditLogType.*/SecAuditLogType Concurrent/" /etc/modsecurity/modsecurity.conf
sudo sed -i "s/SecAuditLog \/.*/SecAuditLog \/var\/log\/mlog2waffle\/modsec_audit.log/" /etc/modsecurity/modsecurity.conf
sudo sed -i "s/#SecAuditLogStorageDir.*/SecAuditLogStorageDir \/var\/log\/mlog2waffle\/data/" /etc/modsecurity/modsecurity.conf

# Creating new directory for the ModSecurity audit log
mkdir -p /opt/modsecurity/var/audit/
chown -R www-data:www-data /opt/modsecurity/var/audit/

# modsecurity apaches module configuration
mv /usr/src/owasp-modsecurity-crs/rules/RESPONSE-950-DATA-LEAKAGES.conf /usr/src/owasp-modsecurity-crs/rules/RESPONSE-950-DATA-LEAKAGES

# Rules to not block mlog2waffle to waffle connection
cat << EOF > /usr/src/ModSecurityRules/Owasp/rules/modsecurity_crs_11_waffle.conf
SecRule REQUEST_FILENAME '^/controller/$' "phase:1,msg:'Match',id:99998,nolog,noauditlog, allow,ctl:RuleEngine=On
SecRule REQUEST_FILENAME '^/yacysearch.html' "phase:1,msg:'Match',id:99999,nolog,noauditlog, allow,ctl:RuleEngine=On
EOF

cat << EOF > /etc/apache2/mods-enabled/security2.conf
<IfModule security2_module>
        # Default Debian dir for modsecurity's persistent data
        SecDataDir /var/cache/modsecurity

        # Include all the *.conf files in /etc/modsecurity.
        # Keeping your local configuration in that directory
        # will allow for an easy upgrade of THIS file and
        # make your life easier
        IncludeOptional /etc/modsecurity/*.conf
        Include /usr/src/ModSecurityRules/Owasp/crs-setup.conf
        Include /usr/src/ModSecurityRules/Owasp/rules/*.conf
        Include /usr/src/ModSecurityRules/Comodo/*.conf
</IfModule>
EOF
}


# ---------------------------------------------------------
# Function to configure modesecurity GUI WAF-FLE
# ---------------------------------------------------------
configure_waffle()
{
   echo "Configuring waf-fle ..." | tee -a /var/libre_config.log
   if [ ! -e  /var/lib/mysql/waffle ]; then
   
      # Defining MySQL user and password variables
      # MYSQL_PASS="librerouter"
      MYSQL_USER="root"

      # Creating MySQL database frnd for waffle
      echo "CREATE DATABASE waffle;" \
      | mysql -u "$MYSQL_USER" -p"$MYSQL_PASS"
      if [ $? -ne 0 ]; then
            echo "Error: Unable to create waf-fle database. Exiting" | tee -a /var/libre_config.log
            exit 3
      fi    

      # Inserting waffle database
      mysql -u root -p"$MYSQL_PASS" waffle < /usr/local/waf-fle/extra/waffle.mysql
      if [ $? -ne 0 ]; then
            echo "Error: Unable to insert waf-fle database. Exiting" | tee -a /var/libre_config.log
            exit 3
      fi    
   fi 
   
# WAF-FLE Configuration File
cat << EOF > /usr/local/waf-fle/config.php
<?PHP
\$DB_HOST  = "localhost";
\$DB_USER  = "root";
\$DB_PASS  = "$MYSQL_PASS";
\$DATABASE = "waffle";
\$COMPRESSION = true;
\$timePreference = 'mili';
\$APC_ON = true; 
\$max_event_number = "25";
\$deleteLimit = 2000;
\$deleteWait = 2;
\$CACHE_TIMEOUT   = 30;
\$SESSION_TIMEOUT = 600;
\$GetSensorInfo = true;
\$PcreErrRuleId = 99999;
\$DEBUG = false;
\$SETUP = false;
?>
EOF

# Apache configuration 
rm -rf /etc/apache2/conf-enabled/waf-fle.conf
cp /usr/local/waf-fle/extra/waf-fle.conf /etc/apache2/conf-enabled/

# Create log directory
mkdir -p /var/log/mlog2waffle/data

# Set permissions
chown www-data /var/log/mlog2waffle/data

cat << EOF > /etc/mlog2waffle.conf
# Configuration file for mlog2waffle
# modsecurity need to be configured to log in concurrent mode, example,
# in Modsecurity config use some thing like this:
#
#   SecAuditLogParts ABIJDEFGHZ
#   SecAuditLogType Concurrent
#   SecAuditLog "/var/log/mlogc/mlogc-index"
#   SecAuditLogStorageDir /var/log/mlogc/data
#
# In this way you can set mlog2waffle to tail mode (see below) and
# check file continuously, sending events in real time to WAF-FLE, or
# run a scheduled "batch" mode.
#
# Requirements: File::Tail perl module, use your own or the provided
# with WAF-FLE package (you may need to ajust the path in mlogc-waffle).

# Define the complete URI of WAF-FLE controller, http or https
\$CONSOLE_URI = "https://waffle.librerouter.net/controller/";

# Define username used to put events on WAF-FLE for this sensor
\$CONSOLE_USERNAME = "librerouter";

# Define password used to put events on WAF-FLE for this sensor
\$CONSOLE_PASSWORD = "admin";

# \$MODSEC_DIRECTORY is where the concurrent audit logs are stored.
# In modsecurity configuration is defined by SecAuditLogStorageDir directive
\$MODSEC_DIRECTORY = "/var/log/mlog2waffle/data/";

# \$INDEX_FILE is defined by SecAuditLog modsecurity directive, it is a index
# file of events generated by concurrent log type
\$INDEX_FILE = "/var/log/mlog2waffle/modsec_audit.log";

# \$ERROR_LOG is a mlogc-waffle error log, write permission is needed.
\$ERROR_LOG = "/var/log/mlog2waffle/mlogc-error.log";

# Define the execution mode:
#  - "tail": for run continuously, waiting for new entries on log file;
#  - "batch": for run and exit at end, but recording (offset file) the
#     position in the last run, speeding up next execution. You can schedule
#     the mlogc-waffle in crontab to run periocally (for example, each 5min).
\$MODE = "tail";

# Set \$FULL_TAIL = "TRUE" to make tail mode read full file at start, set to
# "FALSE" to start to read at end of file.
\$FULL_TAIL = "FALSE";

# \$PIDFILE set the file used to store process id when running in tail mode, forked as a daemon
\$PIDFILE = "/var/run/mlog2waffle.pid";

# Define offset file, used as a checkpoint for batch mode, it need permission
# to write in this file.
\$OFFSET_FILE = "/var/log/mlog2waffle/offset";

# Set the max number of threads used to send parallel events do WAF-FLE,
# if you need more performance to push events to WAF-FLE, try to increase
# to a higher value. Remember, higher number of threads, higher CPU usage.
\$THREADMAX = 2;

# Set \$CHECK_CONNECTIVITY to "TRUE" to check connectivity with WAF-FLE before
# send any event to it. Set to "FALSE" to avoid the check, or for use with
# another console.
\$CHECK_CONNECTIVITY = "TRUE";

# If \$DEBUG is set to "TRUE" it will write in \$DEBUG_FILE the request and response
# between mlogc-waffle and WAF-FLE
\$DEBUG = "FALSE";

# \$DEBUG_FILE
\$DEBUG_FILE = "/var/log/mlog2waffle/mlog2waffle.debug";
EOF

# Preparing mlog2waffle executables
cp /usr/local/waf-fle/extra/mlog2waffle/mlog2waffle /usr/sbin/mlog2waffl
cp /usr/local/waf-fle/extra/mlog2waffle/mlog2waffle.ubuntu /etc/init.d/mlog2waffle

# Configuring sensor information in database
echo "insert into sensors (sensor_id, name, password, description, type, status, client_ip_via) values ('1', 'librerouter', 'admin', 'Main Sensor', '1', 'Enabled', '0')" |  mysql -u root -p"$MYSQL_PASS" waffle
echo "insert into sensors_type (type, Description) values ('1', 'ModSecurity Apache')" |  mysql -u root -p"$MYSQL_PASS" waffle

# Start mlog2waffle
update-rc.d mlog2waffle defaults 99
service mlog2waffle start
}


# ---------------------------------------------------------
# Function to configure apache web server
# ---------------------------------------------------------
configure_apache()
{
# Configuring apache web server
echo "Configuring apache web server ..." | tee -a /var/libre_config.log

# Removing default configuration
rm -rf /etc/apache2/sites-enabled/000-default.conf

# Emabling modules
a2enmod ssl
a2enmod proxy
a2enmod proxy_http
a2enmod proxy_balancer
a2enmod proxy_ajp
a2enmod rewrite
a2enmod deflate
a2enmod headers
a2enmod proxy_connect
a2enmod proxy_html
a2enmod xml2enc
a2enmod fcgid
a2enmod passenger
a2enmod cgi

# Configuring Listen interfaces and ports
echo "
# EasyRTC
Listen 10.0.0.250:80
Listen 10.0.0.250:443

# Yacy
Listen 10.0.0.251:80
Listen 10.0.0.251:443

# Friendica
Listen 10.0.0.252:80
Listen 10.0.0.252:443

# i2p
Listen 10.0.0.1:80

# Mailpile
Listen 10.0.0.254:80
Listen 10.0.0.254:443

# ntop
Listen 10.0.0.244:80
Listen 10.0.0.244:443

# Owncloud
Listen 10.0.0.253:80
Listen 10.0.0.253:443

# Postfix
Listen 10.0.0.242:80
Listen 10.0.0.242:443

# Redmine
Listen 10.0.0.249:80
Listen 10.0.0.249:443

# Roundcube
Listen 10.0.0.243:80
Listen 10.0.0.243:443

# Sogo
Listen 10.0.0.241:80
Listen 10.0.0.241:443

# Squidguard
Listen 10.0.0.246:80
Listen 10.0.0.246:443

# Trac
Listen 10.0.0.248:80
Listen 10.0.0.248:443

# Waf-fle
Listen 10.0.0.238:80
Listen 10.0.0.238:443
 
# Webmin
Listen 10.0.0.245:80
Listen 10.0.0.245:443

# Webconsole
Listen 10.0.0.237:80
Listen 10.0.0.237:443

# Snorby
Listen 10.0.0.239:80
Listen 10.0.0.239:443

# GUI
Listen 10.0.0.236:80
Listen 10.0.0.236:443

# DNS
Listen 10.0.0.235:80
Listen 10.0.0.235:443
" > /etc/apache2/ports.conf


# ----------- search.librerouter.net ------------ #

# Creating certificate bundle
rm -rf /etc/ssl/apache/search/search_bundle.crt
cat /etc/ssl/apache/search/search_librerouter_net.crt /etc/ssl/apache/search/search_librerouter_net.ca-bundle >> /etc/ssl/apache/search/search_bundle.crt

cat << EOF > /etc/apache2/sites-available/yacy.conf
# search.librerouter.net http server
<VirtualHost 10.0.0.251:80>
    ServerAdmin admin@librerouter.net
    ErrorLog \${APACHE_LOG_DIR}/search_error.log
    CustomLog \${APACHE_LOG_DIR}/search_access.log combined
    Redirect "/" "https://search.librerouter.net/"
    # rewrite ^/search(.*) http://\$server_name/yacysearch.html?query=\$arg_q? last;
</VirtualHost>

# search.librerouter.net https server
<VirtualHost 10.0.0.251:443>
    ServerAdmin admin@librerouter.net
    ServerName search.librerouter.net
    ErrorLog \${APACHE_LOG_DIR}/search_error.log
    CustomLog \${APACHE_LOG_DIR}/search_access.log combined
    SSLEngine on
    SSLCertificateFile    /etc/ssl/apache/search/search_bundle.crt
    SSLCertificateKeyFile /etc/ssl/apache/search/search_librerouter_net.key
    ProxyPreserveHost On   
    ProxyPass / http://127.0.0.1:8090/
    ProxyPassReverse / http://127.0.0.1:8090/
</VirtualHost>
EOF


# ---------- conference.librerouter.net ----------- #

# Creating certificate bundle
rm -rf /etc/ssl/apache/conference/conference_bundle.crt
cat /etc/ssl/apache/conference/conference_librerouter_net.crt /etc/ssl/apache/conference/conference_librerouter_net.ca-bundle >> /etc/ssl/apache/conference/conference_bundle.crt

cat << EOF > /etc/apache2/sites-available/easyrtc.conf
# conference.librerouter.net http server
<VirtualHost 10.0.0.250:80>
    ServerAdmin admin@librerouter.net
    ErrorLog \${APACHE_LOG_DIR}/conference_error.log
    CustomLog \${APACHE_LOG_DIR}/conference_access.log combined
    Redirect "/" "https://conference.librerouter.net/demos/demo_multiparty.html"
</VirtualHost>

# conference.librerouter.net https server
<VirtualHost 10.0.0.250:443>
    ServerAdmin admin@librerouter.net
    ServerName conference.librerouter.net
    ErrorLog \${APACHE_LOG_DIR}/conference_error.log
    CustomLog \${APACHE_LOG_DIR}/conference_access.log combined
    SSLEngine on
    SSLCertificateFile    /etc/ssl/apache/conference/conference_bundle.crt
    SSLCertificateKeyFile /etc/ssl/apache/conference/conference_librerouter_net.key
    SSLProxyEngine On
    ProxyPreserveHost On   
    ProxyPass / https://127.0.0.1:8443/
    ProxyPassReverse / https://127.0.0.1:8443/
</VirtualHost>
EOF


# ---------- webmin.librerouter.net ---------- #

# Creating certificate bundle
rm -rf /etc/ssl/apache/webmin/webmin_bundle.crt
cat /etc/ssl/apache/webmin/webmin_librerouter_net.crt /etc/ssl/apache/webmin/webmin_librerouter_net.ca-bundle >> /etc/ssl/apache/webmin/webmin_bundle.crt

cat << EOF > /etc/apache2/sites-available/webmin.conf
# conference.librerouter.net http server
<VirtualHost 10.0.0.245:80>
    ServerAdmin admin@librerouter.net
    ErrorLog \${APACHE_LOG_DIR}/webmin_error.log
    CustomLog \${APACHE_LOG_DIR}/webmin_access.log combined
    Redirect "/" "https://webmin.librerouter.net/"
</VirtualHost>

# conference.librerouter.net https server
<VirtualHost 10.0.0.245:443>
    ServerAdmin admin@librerouter.net
    ServerName webmin.librerouter.net
    ErrorLog \${APACHE_LOG_DIR}/webmin_error.log
    CustomLog \${APACHE_LOG_DIR}/webmin_access.log combined
    SSLEngine on
    SSLCertificateFile    /etc/ssl/apache/webmin/webmin_bundle.crt
    SSLCertificateKeyFile /etc/ssl/apache/webmin/webmin_librerouter_net.key
    ProxyPreserveHost On
    ProxyPass / http://127.0.0.1:10000/
    ProxyPassReverse / http://127.0.0.1:10000/
</VirtualHost>
EOF


# ---------- ntop.librerouter.net ---------- #

# Creating certificate bundle
rm -rf /etc/ssl/apache/ntop/ntop_bundle.crt
cat /etc/ssl/apache/ntop/ntop_librerouter_net.crt /etc/ssl/apache/ntop/ntop_librerouter_net.ca-bundle >> /etc/ssl/apache/ntop/ntop_bundle.crt

cat << EOF > /etc/apache2/sites-available/ntop.conf
# ntop.librerouter.net http server
<VirtualHost 10.0.0.244:80>
    ServerAdmin admin@librerouter.net
    ErrorLog \${APACHE_LOG_DIR}/ntop_error.log
    CustomLog \${APACHE_LOG_DIR}/ntop_access.log combined
    Redirect "/" "https://ntop.librerouter.net/"
</VirtualHost>

# ntop.librerouter.net https server
<VirtualHost 10.0.0.244:443>
    ServerAdmin admin@librerouter.net
    ServerName ntop.librerouter.net
    ErrorLog \${APACHE_LOG_DIR}/ntop_error.log
    CustomLog \${APACHE_LOG_DIR}/ntop_access.log combined
    SSLEngine on
    SSLCertificateFile    /etc/ssl/apache/ntop/ntop_bundle.crt
    SSLCertificateKeyFile /etc/ssl/apache/ntop/ntop_librerouter_net.key
    ProxyPreserveHost On
    ProxyPass / http://127.0.0.1:3030/ retry=2 acquire=3000 timeout=1200 Keepalive=On
    ProxyPassReverse / http://127.0.0.1:3030/
    RequestHeader set X-Forwarded-Proto "https"
    RequestHeader set X-Forwarded-Port "443"
</VirtualHost>
EOF


# ---------- sogo.librerouter.net ---------- #

# Creating certificate bundle
rm -rf /etc/ssl/apache/sogo/sogo_bundle.crt
cat /etc/ssl/apache/sogo/sogo_librerouter_net.crt /etc/ssl/apache/sogo/sogo_librerouter_net.ca-bundle >> /etc/ssl/apache/sogo/sogo_bundle.crt
    
cat << EOF > /etc/apache2/sites-available/sogo.conf
# sogo.librerouter.net http server
<VirtualHost 10.0.0.241:80>
    ServerAdmin admin@librerouter.net
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
    Redirect "/" "https://sogo.librerouter.net/"
</VirtualHost>

# sogo.librerouter.net https server
<VirtualHost 10.0.0.241:443>
    ServerAdmin admin@librerouter.net
    ServerName sogo.librerouter.net
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
    SSLEngine on
    SSLCertificateFile    /etc/ssl/apache/sogo/sogo_bundle.crt
    SSLCertificateKeyFile /etc/ssl/apache/sogo/sogo_librerouter_net.key

Alias /SOGo.woa/WebServerResources/ \
      /usr/lib/GNUstep/SOGo/WebServerResources/
Alias /SOGo/WebServerResources/ \
      /usr/lib/GNUstep/SOGo/WebServerResources/

<Directory /usr/lib/GNUstep/SOGo/>
    AllowOverride None

    <IfVersion < 2.4>
        Order deny,allow
        Allow from all
    </IfVersion>
    <IfVersion >= 2.4>
        Require all granted
    </IfVersion>

    # Explicitly allow caching of static content to avoid browser specific behavior.
    # A resource's URL MUST change in order to have the client load the new version.
    <IfModule expires_module>
      ExpiresActive On
      ExpiresDefault "access plus 1 year"
    </IfModule>
</Directory>

RewriteEngine  on
RewriteRule   ^/$  /SOGo/  [R]

## Uncomment the following to enable proxy-side authentication, you will then
## need to set the "SOGoTrustProxyAuthentication" SOGo user default to YES and
## adjust the "x-webobjects-remote-user" proxy header in the "Proxy" section
## below.
#
## For full proxy-side authentication:
#<Location /SOGo>
#  AuthType XXX
#  Require valid-user
#  SetEnv proxy-nokeepalive 1
#  Allow from all
#</Location>
#
## For proxy-side authentication only for CardDAV and GroupDAV from external
## clients:
#<Location /SOGo/dav>
#  AuthType XXX
#  Require valid-user
#  SetEnv proxy-nokeepalive 1
#  Allow from all
#</Location>

ProxyRequests Off
SetEnv proxy-nokeepalive 1
ProxyPreserveHost On

# When using CAS, you should uncomment this and install cas-proxy-validate.py
# in /usr/lib/cgi-bin to reduce server overloading
#
# ProxyPass /SOGo/casProxy http://localhost/cgi-bin/cas-proxy-validate.py
# <Proxy http://localhost/app/cas-proxy-validate.py>
#   Order deny,allow
#   Allow from your-cas-host-addr
# </Proxy>

# Enable to use Microsoft ActiveSync support
# Note that you MUST have many sogod workers to use ActiveSync.
# See the SOGo Installation and Configuration guide for more details.
#
#ProxyPass /Microsoft-Server-ActiveSync \
# http://127.0.0.1:20000/SOGo/Microsoft-Server-ActiveSync \
# retry=60 connectiontimeout=5 timeout=360

ProxyPass /SOGo http://127.0.0.1:20000/SOGo retry=0

<Proxy http://127.0.0.1:20000/SOGo>

## adjust the following to your configuration
## and do not forget to enable the headers module
<IfModule headers_module>
  RequestHeader set "x-webobjects-server-port" "443"
  RequestHeader set "x-webobjects-server-name" "%{HTTP_HOST}e" env=HTTP_HOST
  RequestHeader set "x-webobjects-server-url" "https://%{HTTP_HOST}e" env=HTTP_HOST

## When using proxy-side autentication, you need to uncomment and
## adjust the following line:
  RequestHeader unset "x-webobjects-remote-user"
#  RequestHeader set "x-webobjects-remote-user" "%{REMOTE_USER}e" env=REMOTE_USER

  RequestHeader set "x-webobjects-server-protocol" "HTTP/1.0"
</IfModule>

  AddDefaultCharset UTF-8
  Order allow,deny
  Allow from all
</Proxy>

# For Apple autoconfiguration
<IfModule rewrite_module>
  RewriteEngine On
  RewriteRule ^/.well-known/caldav/?$ /SOGo/dav [R=301]
  RewriteRule ^/.well-known/carddav/?$ /SOGo/dav [R=301]
</IfModule>
</VirtualHost>
EOF


# ---------- redmine.librerouter.net ---------- #

# Creating certificate bundle
rm -rf /etc/ssl/apache/redmine/redmine_bundle.crt
cat /etc/ssl/apache/redmine/redmine_librerouter_net.crt /etc/ssl/apache/redmine/redmine_librerouter_net.ca-bundle >> /etc/ssl/apache/redmine/redmine_bundle.crt

cat << EOF > /etc/apache2/sites-available/redmine.conf
# redmine.librerouter.net http server
<VirtualHost 10.0.0.249:80>
    ServerAdmin admin@librerouter.net
    ErrorLog \${APACHE_LOG_DIR}/redmine_error.log
    CustomLog \${APACHE_LOG_DIR}/redmine_access.log combined
    Redirect "/" "https://redmine.librerouter.net/"
</VirtualHost>

# redmine.librerouter.net https server
<VirtualHost 10.0.0.249:443>
    ServerAdmin admin@librerouter.net
    ServerName redmine.librerouter.net
    ErrorLog \${APACHE_LOG_DIR}/redmine_error.log
    CustomLog \${APACHE_LOG_DIR}/redmine_access.log combined
    SSLEngine on
    SSLCertificateFile    /etc/ssl/apache/redmine/redmine_bundle.crt
    SSLCertificateKeyFile /etc/ssl/apache/redmine/redmine_librerouter_net.key

    RewriteEngine  on
    RewriteRule   ^/$  /redmine/  [R]

    DocumentRoot /var/www  
    RailsBaseURI /redmine

    <Directory /var/www>   
      Options FollowSymLinks     
      order allow,deny
      allow from all
    </Directory> 

</VirtualHost>
EOF


# ---------- storage.librerouter.net ---------- #

# Creating certificate bundle
rm -rf /etc/ssl/apache/storage/storage_bundle.crt
cat /etc/ssl/apache/storage/storage_librerouter_net.crt /etc/ssl/apache/storage/storage_librerouter_net.ca-bundle >> /etc/ssl/apache/storage/storage_bundle.crt

cat << EOF > /etc/apache2/sites-available/storage.conf
# storage.librerouter.net http server
<VirtualHost 10.0.0.253:80>
    ServerAdmin admin@librerouter.net
    ErrorLog \${APACHE_LOG_DIR}/storage_error.log
    CustomLog \${APACHE_LOG_DIR}/storage_access.log combined
    Redirect "/" "https://storage.librerouter.net/"
</VirtualHost>

# storage.librerouter.net https server
<VirtualHost 10.0.0.253:443>
    ServerAdmin admin@librerouter.net
    ServerName storage.librerouter.net
    ErrorLog \${APACHE_LOG_DIR}/storage_error.log
    CustomLog \${APACHE_LOG_DIR}/storage_access.log combined
    SSLEngine on
    SSLCertificateFile    /etc/ssl/apache/storage/storage_bundle.crt
    SSLCertificateKeyFile /etc/ssl/apache/storage/storage_librerouter_net.key
    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"
    Header set X-Frame-Options "ALLOW-FROM https://gui.librerouter.net"
    DocumentRoot /var/www/nextcloud

    <Directory /var/www/nextcloud/>
      Options +FollowSymlinks
      AllowOverride All

    <IfModule mod_security2.c>
      SecRuleRemoveById 911100
      SecRuleRemoveById 949110
      SecRuleRemoveById 980130
    </IfModule>

    <IfModule mod_dav.c>
      Dav off
    </IfModule>

    SetEnv HOME /var/www/nextcloud
    SetEnv HTTP_HOME /var/www/nextcloud

    </Directory>

</VirtualHost>
EOF


# ---------- roundcube.librerouter.net ---------- #

# Creating certificate bundle
rm -rf /etc/ssl/apache/roundcube/roundcube_bundle.crt
cat /etc/ssl/apache/roundcube/roundcube_librerouter_net.crt /etc/ssl/apache/roundcube/roundcube_librerouter_net.ca-bundle >> /etc/ssl/apache/roundcube/roundcube_bundle.crt

cat << EOF > /etc/apache2/sites-available/roundcube.conf
# roundcube.librerouter.net http server
<VirtualHost 10.0.0.243:80>
    ServerAdmin admin@librerouter.net
    ErrorLog \${APACHE_LOG_DIR}/roundcube_error.log
    CustomLog \${APACHE_LOG_DIR}/roundcube_access.log combined
    Redirect "/" "https://roundcube.librerouter.net/"
</VirtualHost>

# roundcube.librerouter.net https server
<VirtualHost 10.0.0.243:443>
    ServerAdmin admin@librerouter.net
    ServerName roundcube.librerouter.net
    ErrorLog \${APACHE_LOG_DIR}/storage_error.log
    CustomLog \${APACHE_LOG_DIR}/storage_access.log combined
    SSLEngine on
    SSLCertificateFile    /etc/ssl/apache/roundcube/roundcube_bundle.crt
    SSLCertificateKeyFile /etc/ssl/apache/roundcube/roundcube_librerouter_net.key

    DocumentRoot /usr/share/roundcube

   <Directory />
    Options +FollowSymLinks
    # AddDefaultCharset UTF-8
    AddType text/x-component .htc

    <IfModule mod_php5.c>
    AddType application/x-httpd-php .php
    php_flag display_errors Off
    php_flag log_errors On
    # php_value error_log logs/errors
    php_value upload_max_filesize 10M
    php_value post_max_size 12M
    php_value memory_limit 64M
    php_flag zlib.output_compression Off
    php_flag magic_quotes_gpc Off
    php_flag magic_quotes_runtime Off
    php_flag zend.ze1_compatibility_mode Off
    php_flag suhosin.session.encrypt Off
    #php_value session.cookie_path /
    php_flag session.auto_start Off
    php_value session.gc_maxlifetime 21600
    php_value session.gc_divisor 500
    php_value session.gc_probability 1
    </IfModule>

    <IfModule mod_rewrite.c>
    RewriteEngine On
    RewriteRule ^favicon\.ico$ skins/larry/images/favicon.ico
    # security rules:
    # - deny access to files not containing a dot or starting with a dot
    # in all locations except installer directory
    # RewriteRule ^(?!installer)(\.?[^\.]+)$ - [F]
    # - deny access to some locations
    RewriteRule ^/?(\.git|\.tx|SQL|bin|config|logs|temp|tests|program\/(include|lib|localization|steps)) - [F]
    # - deny access to some documentation files
    RewriteRule /?(README\.md|composer\.json-dist|composer\.json|package\.xml)$ - [F]
    </IfModule>

    <IfModule mod_deflate.c>
    SetOutputFilter DEFLATE
    </IfModule>

    <IfModule mod_expires.c>
    ExpiresActive On
    ExpiresDefault "access plus 1 month"
    </IfModule>

    FileETag MTime Size

    <IfModule mod_autoindex.c>
    Options -Indexes
    </ifModule>

    AllowOverride None
    Require all granted
   </Directory>

   <Directory /plugins/enigma/home>
    Options -FollowSymLinks
    AllowOverride None
    Require all denied
   </Directory>

   <Directory /config>
    Options -FollowSymLinks
    AllowOverride None
    Require all denied
   </Directory>

   <Directory /temp>
    Options -FollowSymLinks
    AllowOverride None
    Require all denied
   </Directory>

   <Directory /logs>
    Options -FollowSymLinks
    AllowOverride None
    Require all denied
   </Directory>

</VirtualHost>
EOF


# ---------- squidguard.librerouter.net ---------- #

# Creating certificate bundle
rm -rf /etc/ssl/apache/squidguard/squidguard_bundle.crt
cat /etc/ssl/apache/squidguard/squidguard_librerouter_net.crt /etc/ssl/apache/squidguard/squidguard_librerouter_net.ca-bundle >> /etc/ssl/apache/squidguard/squidguard_bundle.crt

cat << EOF > /etc/apache2/sites-available/squidguard.conf
# squidguard.librerouter.net http server
<VirtualHost 10.0.0.246:80>
    ServerAdmin admin@librerouter.net
    ErrorLog \${APACHE_LOG_DIR}/squidgurad_error.log
    CustomLog \${APACHE_LOG_DIR}/squidguard_access.log combined
    Redirect "/" "https://squidguard.librerouter.net/"
</VirtualHost>

# squidguard.librerouter.net https server
<VirtualHost 10.0.0.246:443>
    ServerAdmin admin@librerouter.net
    ServerName squidguard.librerouter.net
    DocumentRoot /var/www/squidguardmgr
    ErrorLog \${APACHE_LOG_DIR}/squidguard_error.log
    CustomLog \${APACHE_LOG_DIR}/squidguard_access.log combined
    SSLEngine on
    SSLCertificateFile    /etc/ssl/apache/squidguard/squidguard_bundle.crt
    SSLCertificateKeyFile /etc/ssl/apache/squidguard/squidguard_librerouter_net.key

    <Directory /var/www/squidguardmgr>
        Options +ExecCGI
        AddHandler cgi-script .cgi
        DirectoryIndex squidguardmgr.cgi
        AllowOverride All
        Order deny,allow
        Allow from all
    </Directory>

</VirtualHost>
EOF


# ---------- email.librerouter.net ---------- #

# Creating certificate bundle
rm -rf /etc/ssl/apache/email/email_bundle.crt
cat /etc/ssl/apache/email/email_librerouter_net.crt /etc/ssl/apache/email/email_librerouter_net.ca-bundle >> /etc/ssl/apache/email/email_bundle.crt

cat << EOF > /etc/apache2/sites-available/mailpile.conf
# email.librerouter.net http server
<VirtualHost 10.0.0.254:80>
    ServerAdmin admin@librerouter.net
    ErrorLog \${APACHE_LOG_DIR}/email_error.log
    CustomLog \${APACHE_LOG_DIR}/email_access.log combined
    Redirect "/" "https://email.librerouter.net/"
</VirtualHost>

# email.librerouter.net https server
<VirtualHost 10.0.0.254:443>
    ServerAdmin admin@librerouter.net
    ServerName email.librerouter.net
    ErrorLog \${APACHE_LOG_DIR}/email_error.log
    CustomLog \${APACHE_LOG_DIR}/email_access.log combined
    SSLEngine on
    SSLCertificateFile    /etc/ssl/apache/email/email_bundle.crt
    SSLCertificateKeyFile /etc/ssl/apache/email/email_librerouter_net.key
    ProxyPreserveHost On
    ProxyPass / http://127.0.0.1:33411/
    ProxyPassReverse / http://127.0.0.1:33411/
</VirtualHost>
EOF


# ---------- snorby.librerouter.net ---------- #

# Creating certificate bundle
rm -rf /etc/ssl/apache/snorby/snorby_bundle.crt
cat /etc/ssl/apache/snorby/snorby_librerouter_net.crt /etc/ssl/apache/snorby/snorby_librerouter_net.ca-bundle >> /etc/ssl/apache/snorby/snorby_bundle.crt

cat << EOF > /etc/apache2/sites-available/snorby.conf
# snorby.librerouter.net http server
<VirtualHost 10.0.0.239:80>
    ServerAdmin admin@librerouter.net
    ErrorLog \${APACHE_LOG_DIR}/snorby_error.log
    CustomLog \${APACHE_LOG_DIR}/snorby_access.log combined
    Redirect "/" "https://snorby.librerouter.net/"
</VirtualHost>

# snorby.librerouter.net https server
<VirtualHost 10.0.0.239:443>
    ServerAdmin admin@librerouter.net
    ServerName snorby.librerouter.net
    ErrorLog \${APACHE_LOG_DIR}/snorby_error.log
    CustomLog \${APACHE_LOG_DIR}/snorby_access.log combined
    SSLEngine on
    SSLCertificateFile    /etc/ssl/apache/snorby/snorby_bundle.crt
    SSLCertificateKeyFile /etc/ssl/apache/snorby/snorby_librerouter_net.key
    ProxyPreserveHost On
    ProxyPass / http://127.0.0.1:3000/
    ProxyPassReverse / http://127.0.0.1:3000/
</VirtualHost>
EOF


# ---------- postfix.librerouter.net ---------- #

# Creating certificate bundle
rm -rf /etc/ssl/apache/postfix/postfix_bundle.crt
cat /etc/ssl/apache/postfix/postfix_librerouter_net.crt /etc/ssl/apache/postfix/postfix_librerouter_net.ca-bundle >> /etc/ssl/apache/postfix/postfix_bundle.crt

cat << EOF > /etc/apache2/sites-available/postfix.conf
# postfix.librerouter.net http server
<VirtualHost 10.0.0.242:80>
    ServerAdmin admin@librerouter.net
    ErrorLog \${APACHE_LOG_DIR}/postfix_error.log
    CustomLog \${APACHE_LOG_DIR}/postfix_access.log combined
    Redirect "/" "https://postfix.librerouter.net/"
</VirtualHost>

# postfix.librerouter.net https server
<VirtualHost 10.0.0.242:443>
    ServerAdmin admin@librerouter.net
    ServerName postfix.librerouter.net
    DocumentRoot /usr/share/postfixadmin
    ErrorLog \${APACHE_LOG_DIR}/postfix_error.log
    CustomLog \${APACHE_LOG_DIR}/postfix_access.log combined
    SSLEngine on
    SSLCertificateFile    /etc/ssl/apache/postfix/postfix_bundle.crt
    SSLCertificateKeyFile /etc/ssl/apache/postfix/postfix_librerouter_net.key
</VirtualHost>
EOF


# ---------- social.librerouter.net ---------- #

# Creating certificate bundle
rm -rf /etc/ssl/apache/social/social_bundle.crt
cat /etc/ssl/apache/social/social_librerouter_net.crt /etc/ssl/apache/social/social_librerouter_net.ca-bundle >> /etc/ssl/apache/social/social_bundle.crt

cat << EOF > /etc/apache2/sites-available/friendica.conf
# social.librerouter.net http server
<VirtualHost 10.0.0.252:80>
    ServerAdmin admin@librerouter.net
    ErrorLog \${APACHE_LOG_DIR}/social_error.log
    CustomLog \${APACHE_LOG_DIR}/social_access.log combined
    Redirect "/" "https://social.librerouter.net/"
</VirtualHost>

# social.librerouter.net https server
<VirtualHost 10.0.0.252:443>
    ServerAdmin admin@librerouter.net
    ServerName social.librerouter.net
    DocumentRoot /var/www/friendica
    ErrorLog \${APACHE_LOG_DIR}/social_error.log
    CustomLog \${APACHE_LOG_DIR}/social_access.log combined
    SSLEngine on
    SSLCertificateFile    /etc/ssl/apache/social/social_bundle.crt
    SSLCertificateKeyFile /etc/ssl/apache/social/social_librerouter_net.key

    <Directory /var/www/friendica>
       Options Indexes FollowSymLinks MultiViews
       AllowOverride All
       Order allow,deny
       allow from all
    </Directory>

</VirtualHost>
EOF


# ---------- waffle.librerouter.net ---------- #

# Creating certificate bundle
rm -rf /etc/ssl/apache/waffle/waffle_bundle.crt
cat /etc/ssl/apache/waffle/waffle_librerouter_net.crt /etc/ssl/apache/waffle/waffle_librerouter_net.ca-bundle >> /etc/ssl/apache/waffle/waffle_bundle.crt

cat << EOF > /etc/apache2/sites-available/waffle.conf
# waffle.librerouter.net http server
<VirtualHost 10.0.0.238:80>
    ServerAdmin admin@librerouter.net
    ErrorLog ${APACHE_LOG_DIR}/waffle_error.log
    CustomLog ${APACHE_LOG_DIR}/waffle_access.log combined
    Redirect "/" "https://waffle.librerouter.net/"
</VirtualHost>

# waffle.librerouter.net https server
<VirtualHost 10.0.0.238:443>
    ServerAdmin admin@librerouter.net
    ServerName waffle.librerouter.net
    ErrorLog ${APACHE_LOG_DIR}/waffle_error.log
    CustomLog ${APACHE_LOG_DIR}/waffle_access.log combined
    SSLEngine on
    SSLCertificateFile    /etc/ssl/apache/waffle/waffle_bundle.crt
    SSLCertificateKeyFile /etc/ssl/apache/waffle/waffle_librerouter_net.key
    RedirectMatch ^/$ https://waffle.librerouter.net/waf-fle

    <Directory /usr/local/waf-fle>
        Options Indexes FollowSymLinks
        AllowOverride None
        Require all granted
    </Directory>

</VirtualHost>
EOF


# ---------- webconsole.librerouter.net ---------- #

# Creating certificate bundle
rm -rf /etc/ssl/apache/webconsole/webconsole_bundle.crt
cat /etc/ssl/apache/webconsole/webconsole_librerouter_net.crt /etc/ssl/apache/webconsole/webconsole_librerouter_net.ca-bundle >> /etc/ssl/apache/webconsole/webconsole_bundle.crt

cat << EOF > /etc/apache2/sites-available/webconsole.conf
# webconsole.librerouter.net http server
<VirtualHost 10.0.0.237:80>
    ServerAdmin admin@librerouter.net
    ErrorLog \${APACHE_LOG_DIR}/webconsole_error.log
    CustomLog \${APACHE_LOG_DIR}/webconsole_access.log combined
    Redirect "/" "https://webconsole.librerouter.net/"
</VirtualHost>

# webconsole.librerouter.net https server
<VirtualHost 10.0.0.237:443>
    ServerAdmin admin@librerouter.net
    ServerName webconsole.librerouter.net
    DocumentRoot /var/www/webconsole
    DirectoryIndex webconsole.php
    ErrorLog \${APACHE_LOG_DIR}/webconsole_error.log
    CustomLog \${APACHE_LOG_DIR}/webconsole_access.log combined
    SSLEngine on
    SSLCertificateFile    /etc/ssl/apache/webconsole/webconsole_bundle.crt
    SSLCertificateKeyFile /etc/ssl/apache/webconsole/webconsole_librerouter_net.key
</VirtualHost>
EOF


# ---------- trac.librerouter.net ---------- #

# Creating certificate bundle
rm -rf /etc/ssl/apache/trac/trac_bundle.crt
cat /etc/ssl/apache/trac/trac_librerouter_net.crt /etc/ssl/apache/trac/trac_librerouter_net.ca-bundle >> /etc/ssl/apache/trac/trac_bundle.crt

cat << EOF > /etc/apache2/sites-available/trac.conf
# trac.librerouter.net http server
<VirtualHost 10.0.0.248:80>
    ServerAdmin admin@librerouter.net
    ErrorLog \${APACHE_LOG_DIR}/trac_error.log
    CustomLog \${APACHE_LOG_DIR}/trac_access.log combined
    Redirect "/" "https://trac.librerouter.net/"
</VirtualHost>

# trac.librerouter.net https server
<VirtualHost 10.0.0.248:443>
    ServerAdmin admin@librerouter.net
    ServerName trac.librerouter.net
    ErrorLog \${APACHE_LOG_DIR}/trac_error.log
    CustomLog \${APACHE_LOG_DIR}/trac_access.log combined
    SSLEngine on
    SSLCertificateFile    /etc/ssl/apache/trac/trac_bundle.crt
    SSLCertificateKeyFile /etc/ssl/apache/trac/trac_librerouter_net.key
    ProxyPreserveHost On
    ProxyPass / http://127.0.0.1:8000/
    ProxyPassReverse / http://127.0.0.1:8000/
</VirtualHost>
EOF


# ---------- gitlab.librerouter.net ---------- #

# Creating certificate bundle
rm -rf /etc/ssl/apache/gitlab/gitlab_bundle.crt
cat /etc/ssl/apache/gitlab/gitlab_librerouter_net.crt /etc/ssl/apache/gitlab/gitlab_librerouter_net.ca-bundle >> /etc/ssl/apache/gitlab/gitlab_bundle.crt

cat << EOF > /etc/apache2/sites-available/gitlab.conf
# gitlab.librerouter.net http server
<VirtualHost 10.0.0.247:80>
    ServerAdmin admin@librerouter.net
    ErrorLog \${APACHE_LOG_DIR}/gitlab_error.log
    CustomLog \${APACHE_LOG_DIR}/gitlab_access.log combined
    Redirect "/" "https://gitlab.librerouter.net/"
</VirtualHost>

# gitlab.librerouter.net https server
<VirtualHost 10.0.0.247:443>
    ServerAdmin admin@librerouter.net
    ServerName gitlab.librerouter.net
    ErrorLog \${APACHE_LOG_DIR}/gitlab_error.log
    CustomLog \${APACHE_LOG_DIR}/gitlab_access.log combined
    SSLEngine on
    SSLCertificateFile    /etc/ssl/apache/gitlab/gitlab_bundle.crt
    SSLCertificateKeyFile /etc/ssl/apache/gitlab/gitlab_librerouter_net.key

  Header set X-Frame-Options "ALLOW-FROM https://gui.librerouter.net"
  ServerSignature Off
  ProxyPreserveHost On

  # Ensure that encoded slashes are not decoded but left in their encoded state.
  # http://doc.gitlab.com/ce/api/projects.html#get-single-project
  AllowEncodedSlashes NoDecode

  <Location />
    # New authorization commands for apache 2.4 and up
    # http://httpd.apache.org/docs/2.4/upgrading.html#access
    Require all granted

    #Allow forwarding to gitlab-workhorse
    ProxyPassReverse http://127.0.0.1:8081
    ProxyPassReverse http://gitlab.librerouter.net/
  </Location>

  # Apache equivalent of nginx try files
  # http://serverfault.com/questions/290784/what-is-apaches-equivalent-of-nginxs-try-files
  # http://stackoverflow.com/questions/10954516/apache2-proxypass-for-rails-app-gitlab
  RewriteEngine on

  #Forward all requests to gitlab-workhorse except existing files like error documents
  RewriteCond %{DOCUMENT_ROOT}/%{REQUEST_FILENAME} !-f [OR]
  RewriteCond %{REQUEST_URI} ^/uploads/.*
  RewriteRule .* http://127.0.0.1:8081%{REQUEST_URI} [P,QSA,NE]

  # needed for downloading attachments
  DocumentRoot /opt/gitlab/embedded/service/gitlab-rails/public

  #Set up apache error documents, if back end goes down (i.e. 503 error) then a maintenance/deploy page is thrown up.
  ErrorDocument 404 /404.html
  ErrorDocument 422 /422.html
  ErrorDocument 500 /500.html
  ErrorDocument 502 /502.html
  ErrorDocument 503 /503.html
</VirtualHost>
EOF


# ---------- gui.librerouter.net ---------- #

# Creating certificate bundle
rm -rf /etc/ssl/apache/gui/gui_bundle.crt
cat /etc/ssl/apache/gui/gui_librerouter_net.crt /etc/ssl/apache/gui/gui_librerouter_net.ca-bundle >> /etc/ssl/apache/gui/gui_bundle.crt

cat << EOF > /etc/apache2/sites-available/gui.conf
# gui.librerouter.net http server
<VirtualHost 10.0.0.236:80>
ServerAdmin admin@librerouter.net
    ServerName gui.librerouter.net
    ErrorLog \${APACHE_LOG_DIR}/gui_error.log
    CustomLog \${APACHE_LOG_DIR}/gui_access.log combined
    Redirect "/" "https://gui.librerouter.net/"
</VirtualHost>

# gui.librerouter.net https server
<VirtualHost 10.0.0.236:443>
    ServerAdmin admin@librerouter.net
    ServerName gui.librerouter.net
    DocumentRoot /var/www/gui
    ErrorLog \${APACHE_LOG_DIR}/gui_error.log
    CustomLog \${APACHE_LOG_DIR}/gui_access.log combined
    SSLEngine on
    SSLCertificateFile    /etc/ssl/apache/gui/gui_bundle.crt
    SSLCertificateKeyFile /etc/ssl/apache/gui/gui_librerouter_net.key

    DocumentRoot /var/www/gui
    AddHandler cgi-script .cgi
    <IfModule dir_module>
      DirectoryIndex index.cgi index.php index.html
    </IfModule>

    <Directory /var/www/gui>
       Options Indexes FollowSymLinks MultiViews ExecCGI
       AllowOverride All
       Order allow,deny
       allow from all
    </Directory>

</VirtualHost>
EOF


# ---------- dns.librerouter.net ---------- #

# Creating certificate bundle
rm -rf /etc/ssl/apache/dns/dns_bundle.crt
cat /etc/ssl/apache/dns/dns_librerouter_net.crt /etc/ssl/apache/dns/dns_librerouter_net.ca-bundle >> /etc/ssl/apache/dns/dns_bundle.crt

cat << EOF > /etc/apache2/sites-available/dns.conf
# dns.librerouter.net http server
<VirtualHost 10.0.0.235:80>
    ServerAdmin admin@librerouter.net
    ErrorLog \${APACHE_LOG_DIR}/dns_error.log
    CustomLog \${APACHE_LOG_DIR}/dns_access.log combined
    Redirect "/" "https://dns.librerouter.net"
</VirtualHost>

# dns.librerouter.net https server
<VirtualHost 10.0.0.235:443>
    ServerAdmin admin@librerouter.net
    ServerName dns.librerouter.net
    ErrorLog \${APACHE_LOG_DIR}/dns_error.log
    CustomLog \${APACHE_LOG_DIR}/dns_access.log combined
    SSLEngine on
    SSLCertificateFile    /etc/ssl/apache/dns/dns_bundle.crt
    SSLCertificateKeyFile /etc/ssl/apache/dns/dns_librerouter_net.key
    SSLProxyEngine On
    ProxyPreserveHost On

    RewriteRule ^/$ https://dns.librerouter.net/admin [R=301,NC,L]

    <Location />
        ProxyPass http://10.0.0.2:80/
        ProxyPassReverse http://dns.librerouter.net/
    </Location>
</VirtualHost>
EOF


# ---------- warning.librerouter.net ---------- #

cat << EOF > /etc/apache2/sites-available/warning.conf
# warning.librerouter.net http server
<VirtualHost 10.0.0.1:80>
    ServerName warning.librerouter.net
    ServerAdmin admin@librerouter.net
    ErrorLog \${APACHE_LOG_DIR}/warning_error.log
    CustomLog \${APACHE_LOG_DIR}/warning_access.log combined
    DocumentRoot /var/www/html
</VirtualHost>
EOF


# Enabling Services
a2ensite easyrtc
a2ensite ntop
a2ensite roundcube
a2ensite squidguard
a2ensite waffle
a2ensite webmin
a2ensite friendica
a2ensite gui
a2ensite dns
a2ensite postfix
a2ensite snorby
a2ensite storage
a2ensite warning
a2ensite yacy
a2ensite gitlab
a2ensite mailpile
a2ensite redmine
a2ensite sogo
a2ensite trac
a2ensite webconsole


# Restarting apache
echo "Restarting apache web server ..." | tee -a /var/libre_config.log
update-rc.d apache2 defaults
/etc/init.d/apache2 restart
}


# ---------------------------------------------------------
# Function to check interfaces
# ---------------------------------------------------------
check_interfaces()
{
# Preparing script file
touch /root/libre_scripts/check_interfaces.sh
chmod +x /root/libre_scripts/check_interfaces.sh


# Script to check interfaces
cat << EOF > /root/libre_scripts/check_interfaces.sh
#!/bin/bash
# Checking physical interfaces (eth0 and eth1)
if ip addr show eth1 | grep 'state UP'; then
if ip addr show eth0 | grep 'state UP'; then
# Checking virtual interfaces (ethx:1 ethx:2 ethx:3 ethx:4 ethx:5 ethx:6)
    if ping -c 1 10.0.0.245; then
	if ping -c 1 10.0.0.250; then
	    if ping -c 1 10.0.0.251; then
		if ping -c 1 10.0.0.252; then
		    if ping -c 1 10.0.0.253; then
			if ping -c 1 10.0.0.254; then
			    logger "Check Interfaces: Network is ok"
			else
			    #Make a note in syslog
			    logger "Check Interfaces: ethx:4 is down, restarting network ..."
			    /etc/init.d/networking restart
			    exit
			fi
		    else
			#Make a note in syslog
			logger "Check Interfaces: ethx:3 is down, restarting network ..."
			/etc/init.d/networking restart
			exit
		    fi
		else
		    #Make a note in syslog
		    logger "Check Interfaces: ethx:2 is down, restarting network ..."
		    /etc/init.d/networking restart
		    exit
		fi
	    else
		#Make a note in syslog
		logger "Check Interfaces: ethx:1 is down, restarting network ..."
		/etc/init.d/networking restart
		exit
	    fi
	else
	    #Make a note in syslog
	    logger "Check Interfaces: ethx:6 is down, restarting network ..."
	    /etc/init.d/networking restart
	    exit
	fi
    else
	#Make a note in syslog
	logger "Check Interfaces: ethx:5 is down, restarting network ..."
	/etc/init.d/networking restart
	exit
    fi
else
#Make a note in syslog
logger "Check Interfaces: eth0 is down, restarting network ..."
/etc/init.d/networking restart
exit
fi
else
#Make a note in syslog
logger "Check Interfaces: eth1 is down, restarting network ..."
/etc/init.d/networking restart
exit
fi
EOF


# Creating cron job
echo "@reboot sleep 20 && /root/libre_scripts/check_interfaces.sh" >> /root/libre_scripts/cron_jobs
crontab /root/libre_scripts/cron_jobs

# Make script to run when network interface goes down
rm -rf /etc/network/if-post-down.d/check_interfaces.sh
rm -rf /etc/network/if-up.d/check_interfaces.sh
cp /root/libre_scripts/check_interfaces.sh /etc/network/if-post-down.d/
cp /root/libre_scripts/check_interfaces.sh /etc/network/if-up.d
}


# ---------------------------------------------------------
# Function to check services
# ---------------------------------------------------------
check_services()
{
# Preparing script file
rm -rf /root/libre_scripts/check_services.sh
touch /root/libre_scripts/check_services.sh
chmod +x /root/libre_scripts/check_services.sh


# Script to check services
cat << EOF > /root/libre_scripts/check_services.sh
#!/bin/bash
# Checking unbound
if /etc/init.d/unbound status | grep "active (running)"; then
logger "Check Services: Unbound is ok"
else
logger "Check Services: Unbound is not running. Restarting ..."
/etc/init.d/unbound restart
fi

# Checking isc-dhcp-server
if /etc/init.d/isc-dhcp-server status | grep "active (running)"; then
logger "Check Services: isc-dhcp-server is ok"
else
logger "Check Services: isc-dhcp-server is not running. Restarting ..."
/etc/init.d/isc-dhcp-server restart
fi

# Checking squid
if /etc/init.d/squid status | grep "active (running)"; then
logger "Check Services: squid is ok"
else
logger "Check Services: squid is not running. Restarting ..."
/etc/init.d/squid restart
fi

# Checking squid-tor
if /etc/init.d/squid-tor status | grep "active (running)"; then
logger "Check Services: squid-tor is ok"
else
logger "Check Services: squid-tor is not running. Restarting ..."
/etc/init.d/squid-tor restart
fi

# Checking squid-i2p
if /etc/init.d/squid-i2p status | grep "active (running)"; then
logger "Check Services: squid-i2p is ok"
else
logger "Check Services: squid-i2p is not running. Restarting ..."
/etc/init.d/squid-i2p restart
fi

# Checking clamav-daemon
if /etc/init.d/clamav-daemon status | grep "active (running)"; then
logger "Check Services: clamav-daemon is ok"
else
logger "Check Services: clamav-daemon is not running. Restarting ..."
/etc/init.d/clamav-daemon restart
fi

# Checking c-icap
if /etc/init.d/c-icap status | grep "active (running)"; then
logger "Check Services: c-icap is ok"
else
logger "Check Services: c-icap is not running. Restarting ..."
/etc/init.d/c-icap restart
fi

# Checking privoxy
if /etc/init.d/privoxy status | grep "active (running)"; then
logger "Check Services: privoxy is ok"
else
logger "Check Services: privoxy is not running. Restarting ..."
/etc/init.d/privoxy restart
fi

# Checking privoxy-tor
if /etc/init.d/privoxy-tor status | grep "active (running)"; then
logger "Check Services: privoxy-tor is ok"
else
logger "Check Services: privoxy-tor is not running. Restarting ..."
/etc/init.d/privoxy-tor restart
fi

# Checking apache
if /etc/init.d/apache2 status | grep "active (running)"; then
logger "Check Services: Apache is ok"
else
logger "Check Services: Apache is not running. Restarting ..."
/etc/init.d/apache2 restart
fi
EOF


# Creating cron job
echo "@reboot sleep 40 && /root/libre_scripts/check_interfaces.sh" >> /root/libre_scripts/cron_jobs
crontab /root/libre_scripts/cron_jobs
}


# ---------------------------------------------------------
# Function to configure Suricata service
# ---------------------------------------------------------
configure_suricata()
{
echo "Configuring Suricata ..." | tee -a /var/libre_config.log

#prepare network interface to work with suricata
echo "peparing the network interfaces ..."
ethtool -K lo rx off tso off gso off sg off gro off lro off
ifconfig lo mtu 1400

# Suricata service
cat << EOF > /etc/default/suricata
# Default config for Suricata

# set to yes to start the server in the init.d script
RUN=yes

# Configuration file to load
SURCONF=/etc/suricata/suricata-debian.yaml

# Listen mode: pcap or nfqueue
# depending on this value, only one of the two following options
# will be used
# Please note that IPS mode is only available when using nfqueue
LISTENMODE=nfqueue

# Interface to listen on (for pcap mode)
IFACE=lo

# Queue number to listen on (for nfqueue mode)
NFQUEUE=0

# Load Google TCMALLOC if libtcmalloc-minimal0 is installed
# This _might_ give you very very small performance gain....
TCMALLOC="YES"

# Pid file
PIDFILE=/var/run/suricata.pid
EOF

# Suricata-debian configuraion
cat << EOF > /etc/suricata/suricata-debian.yaml
 # alert output for use with Barnyard2
  - unified2-alert:
      enabled: yes
      filename: unified2.alert

      # File size limit.  Can be specified in kb, mb, gb.  Just a number
      # is parsed as bytes.
      limit: 100mb

logging:

  # The default log level, can be overridden in an output section.
  # Note that debug level logging will only be emitted if Suricata was
  # compiled with the --enable-debug configure option.
  #
  # This value is overriden by the SC_LOG_LEVEL env var.
  default-log-level: notice

  # The default output format.  Optional parameter, should default to
  # something reasonable if not provided.  Can be overriden in an
  # output section.  You can leave this out to get the default.
  #
  # This value is overriden by the SC_LOG_FORMAT env var.
  #default-log-format: "[%i] %t - (%f:%l) <%d> (%n) -- "

  # A regex to filter output.  Can be overridden in an output section.
  # Defaults to empty (no filter).
  #
  # This value is overriden by the SC_LOG_OP_FILTER env var.
  default-output-filter:

  # Define your logging outputs.  If none are defined, or they are all
  # disabled you will get the default - console output.
  outputs:
  - console:
      enabled: no
  - file:
      enabled: yes
      filename: /var/log/suricata.log
  - syslog:
      enabled: no
      facility: local5
      format: "[%i] <%d> -- "
EOF

# Logrotate configuration
cat << EOF > /etc/logrotate.d/suricata 
/var/log/suricata/*.log /var/log/suricata/*.json
{
    rotate 3
    missingok
    nocompress
    create
    sharedscripts
    postrotate
            /bin/kill -HUP \$(cat /var/run/suricata.pid)
    endscript
}
EOF

# Restarting Suricata
service suricata restart
}


# ---------------------------------------------------------
# Function to configure logstash
# ---------------------------------------------------------
configure_logstash()
{

echo "Conifgureing logstash ..." | tee -a /var/libre_config.log

# Creating configuration file
mkdir -p /etc/logstash/conf.d
touch /etc/logstash/conf.d/logstash.conf
chmod a+rw /etc/logstash/conf.d/logstash.conf

# Logstash configuration
cat << EOF > /etc/logstash/conf.d/logstash.conf
input {
file {
path => "/var/log/suricata/eve.json"
start_position => beginning
ignore_older => 0
sincedb_path => ["/var/lib/logstash/sincedb"]
codec =>   json
type => "SuricataIDPS"
}
}
filter {
if [type] == "SuricataIDPS" {
date {
match => [ "timestamp", "ISO8601" ]
}
ruby {
code => "if event['event_type'] == 'fileinfo'; event['fileinfo']['type']=event['fileinfo']['magic'].to_s.split(',')[0]; end;"
}
}
if [src_ip]  {
geoip {
source => "src_ip"
target => "geoip"
#database => "/opt/logstash/vendor/geoip/GeoLiteCity.dat"
add_field => [ "[geoip][coordinates]", "%{[geoip][longitude]}" ]
add_field => [ "[geoip][coordinates]", "%{[geoip][latitude]}"  ]
}
mutate {
convert => [ "[geoip][coordinates]", "float" ]
}
if ![geoip.ip] {
if [dest_ip]  {
geoip {
  source => "dest_ip"
  target => "geoip"
  #database => "/opt/logstash/vendor/geoip/GeoLiteCity.dat"
  add_field => [ "[geoip][coordinates]", "%{[geoip][longitude]}" ]
  add_field => [ "[geoip][coordinates]", "%{[geoip][latitude]}"  ]
}
mutate {
  convert => [ "[geoip][coordinates]", "float" ]
}
}
}
}
}
output {
elasticsearch {
hosts => [ "localhost:9200" ]
}
}
EOF
}


# ---------------------------------------------------------
# Function to configure Kibana
# ---------------------------------------------------------
configure_kibana()
{
echo "Configuring Kibana ..." | tee -a /var/libre_config.log

# Configure PAM limits
sed -i -e '/# End of file/d' /etc/security/limits.conf
echo 'elasticsearch hard memlock 102400' >> /etc/security/limits.conf
echo '# End of file' >> /etc/security/limits.conf
# Configure elastic
cat << EOF > /etc/default/elasticsearch
################################
# Elasticsearch
################################

ES_JAVA_OPTS="Des.insecure.allow.root=true"

# Elasticsearch home directory
ES_HOME=/usr/share/elasticsearch

# Elasticsearch configuration directory
CONF_DIR=/etc/elasticsearch

# Elasticsearch data directory
DATA_DIR=/var/lib/elasticsearch

# Elasticsearch logs directory
LOG_DIR=/var/log/elasticsearch

# Elasticsearch PID directory
PID_DIR=/var/run/elasticsearch

# Memory usage
ES_HEAP_SIZE=128m
MAX_LOCKED_MEMORY=102400
ES_JAVA_OPTS=-server

# The number of seconds to wait before checking if Elasticsearch started successfully as a daemon process
ES_STARTUP_SLEEP_TIME=15
EOF

# Elasticsearch configuration
sed -i -e 's/cluster.name.*/cluster.name: "LibreRouter"/g' /etc/elasticsearch/elasticsearch.yml


# Fix logstash permissions
sed -i -e 's/LS_GROUP=.*/LS_GROUP=root/g' /etc/init.d/logstash
systemctl daemon-reload

# Enable autostart
systemctl enable elasticsearch
echo "Restarting elasticsearch ..."
service elasticsearch restart
systemctl enable kibana
systemctl enable logstash

echo "Restarting logstash ..." | tee -a /var/libre_config.log
service logstash restart | tee -a /var/libre_config.log
echo "Applying Kibana dashboards ..." 
sleep 20 && /opt/KTS/load.sh && echo ""
echo "Kibana dashboards were successfully configured" | tee -a /var/libre_config.log
echo "Restarting kibana ..." | tee -a /var/libre_config.log
service kibana restart | tee -a /var/libre_config.log
}


# ---------------------------------------------------------
# Function to configure gitlab
# ---------------------------------------------------------
configure_gitlab()
{
# Gitlab can only be installed on x86_64 (64 bit) architecture
# So we configure it if architecture is x86_64
if [ "$ARCH" == "x86_64" ]; then
	echo "Configuring Gitlab ..." | tee -a /var/libre_config.log

	# Creating certificate bundle
	rm -rf /etc/ssl/apache/gitlab/gitlab_bundle.crt
	cat /etc/ssl/apache/gitlab/gitlab_librerouter_net.crt /etc/ssl/apache/gitlab/gitlab_librerouter_net.ca-bundle >> /etc/ssl/apache/gitlab/gitlab_bundle.crt

	# Changing configuration in gitlab.rb
	sed -i -e '/^[^#]/d' /etc/gitlab/gitlab.rb

	echo "
external_url ['gitlab.librerouter.net', 'gui.librerouter.net']
gitlab_workhorse['auth_backend'] = \"http://localhost:8081\"
unicorn['port'] = 8081
nginx['enable'] = false
web_server['external_users'] = ['www-data']
" >> /etc/gitlab/gitlab.rb

	# Reconfiguring gitlab 
	echo "Reconfiguring gitlab ..." | tee -a /var/libre_config.log
	gitlab-ctl reconfigure | tee -a /var/libre_config.log

	# Restarting gitlab server
	echo "Restarting gitlab ..." | tee -a /var/libre_config.log
	gitlab-ctl restart | tee -a /var/libre_config.log
else
	echo "Gitlab configuration is skipped as detected architecture: $ARCH" | tee -a /var/libre_config.log
fi
}


# -----------------------------------------------
# Function to configure snorby
# -----------------------------------------------
configure_snorby()
{
echo "Configuring Snorby" | tee -a /var/libre_config.log
cat << EOF > /opt/snorby/config/snorby_config.yml
production:
  domain: 'snorby.librerouter.net'
  wkhtmltopdf: /usr/bin/wkhtmltopdf
  ssl: false
  mailer_sender: 'admin@librerouter.net'
  geoip_uri: "http://geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz"
  rules:
    - ""
  authentication_mode: database
EOF

cat << EOF > /opt/snorby/config/database.yml
# Snorby Database Configuration
#
# Please set your database password/user below
# NOTE: Indentation is important.
#
snorby: &snorby
  adapter: mysql
  username: root
  password: "$MYSQL_PASS"
  host: localhost

development:
  database: snorby
  <<: *snorby

test:
  database: snorby
  <<: *snorby

production:
  database: snorby
  <<: *snorby
EOF

cd /opt/snorby

# Generate snorby admin password
SNORBY_PASS=`pwgen 10 1`

# Configure admin user
sed "s/'snorby'/'$SNORBY_PASS'/g" -i /opt/snorby/db/seeds.rb
sed 's/snorby@example.com/admin@librerouter.net/' -i /opt/snorby/db/seeds.rb

# Setup snorby
RAILS_ENV=production bundle exec rake snorby:setup
cd
}


# ---------------------------------------------------------
# Function to configure barnyard
# ---------------------------------------------------------
configure_barnyard()
{
echo "Configuring Barnyard ..." | tee -a /var/libre_config.log

# Barnyard configuration
cat << EOF > /etc/suricata/barnyard2.conf
config reference_file:      /etc/suricata/reference.config
config classification_file: /etc/suricata/classification.config
config gen_file:            /etc/suricata/rules/gen-msg.map
config sid_file:            /etc/suricata/rules/sid-msg.map
config interface: lo
input unified2

# define the full waldo filepath.
config waldo_file: /var/log/suricata/suricata.waldo

# database: log to a variety of databases
output database: log, mysql, user=root password=$MYSQL_PASS dbname=snorby host=localhost sensor_name=Cervin
EOF

mkdir -p /var/log/barnyard2
chmod a+rw /var/log/barnyard2

# Start barnyard2
barnyard2 -c /etc/suricata/barnyard2.conf -d /var/log/suricata -f unified2.alert -w /var/log/suricata/suricata.waldo -D
}


# ---------------------------------------------------------
# Function to configure fail2ban
# ---------------------------------------------------------
configure_fail2ban()
{
rm -rf /etc/fail2ban/jail.conf
touch /etc/fail2ban/jail.conf
chmod 660 /etc/fail2ban/jail.conf
cat << EOF > /etc/fail2ban/jail.conf
[DEFAULT]
ignoreip = 127.0.0.1/8 10.0.0.0/24
bantime = 1200
findtime = 300
maxretry = 5

backend = auto
usedns = warn
destemail = root@localhost.librerouter
sendername = Fail2Ban Alerts
sender = fail2ban@localhost.librerouter
banaction = iptables-multiport
mta = sendmail
protocol = tcp
chain = INPUT

#Types of Bans
action_ = %(banaction)s[name=%(__name__)s, port="%(port)s", protocol="%(protocol)s", chain="%(chain)s"]
action_mw = %(banaction)s[name=%(__name__)s, port="%(port)s", protocol="%(protocol)s", chain="%(chain)s"]
		%(mta)s-whois[name=%(__name__)s, dest="%(destemail)s", protocol="%(protocol)s", chain="%(chain)s", sendername="%(sendername)s"]
action_mwl = %(banaction)s[name=%(__name__)s, port="%(port)s", protocol="%(protocol)s", chain="%(chain)s"]
		%(mta)s-whois-lines[name=%(__name__)s, dest="%(destemail)s", logpath=%(logpath)s, chain="%(chain)s", sendername="%(sendername)s"]

#Default method of ban
action = %(action_)s

#Jails - Securing services..

[ssh]
enabled = true
port 	= ssh
filter 	= sshd
logpath = /var/log/auth.log
maxretry = 4

[nginx-http-auth]
enabled = false
filter	= ngin-http-auth
port	= http,https
logpath = /var/log/nginx/error.log

[roundcube-auth]
enabled = false
filter  = roundcube-auth
port	 = http,https
logpath = /var/log/roundcube/userlogins

[sogo-auth]
enabled	= false
filter	= sogo-auth
port	= http,https
#Without proxy would be 20000
logpath = /var/log/sogo/sogo.log

[postfix]
enabled	= true
port	= smtp,ssmtp,submission
filter	= postfix
logpath = /var/log/mail.log

[dovecot]
enabled	= true
port	= smtp,ssmtp,submission,imap2,imap3,imaps,pop3,pop3s
filter	= dovecot
logpath = /var/log/mail.log

[sasl]
enabled  = true
port     = smtp,ssmtp,submission,imap2,imap3,imaps,pop3,pop3s
filter   = postfix-sasl
logpath  = /var/log/mail.warn

[mysqld-auth]

enabled  = true
filter   = mysqld-auth
port     = 3306
logpath  = /var/log/mysql.log

EOF
service fail2ban stop &> /dev/null
service fail2ban start &> /dev/null

}


# ---------------------------------------------------------
# Function to configure miniupnp
# ---------------------------------------------------------
configure_upnp()
{
echo "Configuring miniupnp ..." | tee -a /var/libre_config.log 
cat <<EOT | grep -v EOT> /root/libre_scripts/upnp.sh
# Get my own IP
myprivip=\$(ifconfig eth0  | grep " addr" | grep -v grep  | cut -d : -f 2 | cut -d  \  -f 1)

# Get my gw lan IP
# This is required to force to select ONLY the UPNP server same where we are ussing as default gateway
# First seek for my default gw IP and then seek for the desc value of the UPNP device
# Use UPNP device desc value as key for send delete/add rules
my_gw_ip=\$(route -n | grep UG | cut -c 17-32)

# Get list of all UPNP devices in lan filtered by my_gw_ip
myupnpdevicedescription=\$(upnpc -l | grep desc: | grep \$my_gw_ip | grep -v grep | sed -e "s/desc: //g")

# now collect ports to configure on router portforwarding, from live iptables
iptlist=\$(iptables -L -n -t nat | grep REDIRECT | grep -v grep | cut -c 63- | sed -e "s/dpt://g" | sed -e "s/spt://g" | cut -d \  -f 1,2 | sed -e "s/tcp/TCP/g" | sed -e "s/udp/UDP/g" | sed -e "s/ //g" | sort | uniq )
roulist=\$(upnpc -l -u \$myupnpdevicedescription | tail -n +17 | grep -v GetGeneric | cut -d \- -f 1 | cut -d \  -f 3- | sed -e "s/ //g")
for lines in \$iptlist; do
    passed=0;
    # check if this port was already forwarded on router
    for routforward in \$roulist; do
       if [ "\$routforwad" = "\$lines" ]; then
            echo "port \$lines was already forwarded" 
       else
         if [ \$passed = 0 ]; then
            # Remove older portforwarding is required when this libreroute is reconnected to internet router and get a different IP from router DHCP service
            protocol=\${lines:0:3}
            port=\${lines:3:8}
            upnpc -u \$myupnpdevicedescription -d \$port \$protocol
            upnpc -u \$myupnpdevicedescription -a \$myprivip \$port \$port \$protocol
            passed=1;  # swap semaphore to void send repeated queries to UPNP server
         fi
       fi
    done
    echo \$lines
done

EOT

chmod u+x /root/libre_scripts/upnp.sh
if [ ! $(cat /var/spool/crontabs/root | grep upnp) ]; then
    echo "0 * * * * /root/libre_scripts/upnp.sh" >> /var/spool/crontabs/root
fi
}


# ---------------------------------------------------------
# Function to configure webconsole
# ---------------------------------------------------------
configure_webconsole()
{
echo "Configuring webconsole ..."  | tee -a /var/libre_config.log

# Creating webconsole users home directory
mkdir -p /var/www/webconsole/home

# Setting Webconsole user login and passoword
WEB_PASS=`pwgen 10 1`
sed "/\$USER = '';/c\$USER = 'web';" -i /var/www/webconsole/webconsole.php
sed "/\$PASSWORD = '';/c\$PASSWORD = \'$WEB_PASS\';" -i /var/www/webconsole/webconsole.php

# Setting webconsole users home directory
sed "/\$HOME_DIRECTORY = '';/c\$HOME_DIRECTORY = '/var/www/webconsole/home';" -i /var/www/webconsole/webconsole.php
}


# ---------------------------------------------------------
# Function to configure MAT (Metadata Anonymisation Toolkit)
# ---------------------------------------------------------
configure_mat()
{
echo "Configuring MAT ..."  | tee -a /var/libre_config.log

# Run cron daily job to remove metadata in nextcloud data direcotry
cat << EOF > /etc/cron.daily/mat
#!/bin/bash
mat /var/www/nextcloud/data
EOF

chmod +x /etc/cron.daily/mat
}


# ---------------------------------------------------------
# Function to configure lighttpd server
# ---------------------------------------------------------
configure_lighttpd()
{
echo "Configuring lighttpd server ..."  | tee -a /var/libre_config.log

# Creating PEM certificate
cat /etc/ssl/apache/initial/initial_librerouter_net.key > /etc/ssl/apache/initial/initial_librerouter_net.pem
cat /etc/ssl/apache/initial/initial_librerouter_net.crt >> /etc/ssl/apache/initial/initial_librerouter_net.pem
cat /etc/ssl/apache/initial/initial_librerouter_net.ca-bundle >> /etc/ssl/apache/initial/initial_librerouter_net.pem

# Creating log file
mkdir -p /var/log/lighttpd
touch /var/log/lighttpd/lighttpd.error.log

# Creating configuration file
mkdir -p /etc/lighttpd
touch /etc/lighttpd/lighttpd.conf

# Creating lighttpd server configuration
cat << EOF > /etc/lighttpd/lighttpd.conf
debug.log-request-handling = "enable"
debug.log-request-header = "enable"
debug.log-response-header = "enable"
#debug.log-condition-handling = "enable"
server.document-root         = "/var/www/gui"

## 64 Mbyte ... nice limit
server.max-request-size = 65000

## bind to port (default: 80)
server.port                 = 2048

## bind to localhost (default: all interfaces)
server.bind                = "10.0.0.234"
server.errorlog            = "/var/log/lighttpd/lighttpd.error.log"
server.breakagelog         = "/var/log//lighttpd/lighttpd.breakage.log"
server.name                = "initial.librerouter.net"
server.tag                 = "Apache 1.3.29"

server.dir-listing          = "enable"

server.modules = (
#       "mod_rewrite",
#       "mod_setenv",
        "mod_secdownload",
        "mod_access",
        "mod_auth",
        "mod_authn_file",
        "mod_status",
        "mod_expire",
        "mod_simple_vhost",
        "mod_redirect",
        "mod_fastcgi",
        "mod_cgi",
        "mod_compress",
        "mod_userdir",
        "mod_ssi",
        "mod_accesslog",
)

server.indexfiles = (
        "index.cgi",
)

######################## MODULE CONFIG ############################

ssi.extension = (
        ".shtml",
)

accesslog.filename = "/var/log/lighttpd/lighttpd.access.log"

mimetype.assign = (
        ".png"  => "image/png",
        ".jpg"  => "image/jpeg",
        ".jpeg" => "image/jpeg",
        ".gif"  => "image/gif",
        ".html" => "text/html",
        ".htm"  => "text/html",
        ".txt"  => "text/plain",
)

compress.filetype = (
        "text/plain",
        "text/html",
)

setenv.add-environment = (
        "TRAC_ENV" => "tracenv",
        "SETENV" => "setenv",
)
setenv.add-request-header = (
        "FOO" => "foo",
)
setenv.add-response-header = (
        "BAR" => "foo",
)

\$HTTP["url"] =~ "\.pdf\$" {
        server.range-requests = "disable"
}

fastcgi.debug = 0
fastcgi.server = (
        ".php" => ( (
                "host" => "127.0.0.1",
                "port" => 1026,
                "broken-scriptfilename" => "enable",
                "allow-x-send-file" => "enable",
        ) ),
        "/prefix.fcgi" => ( (
                "host" => "127.0.0.1",
                "port" => 1026,
                "check-local" => "disable",
                "broken-scriptfilename" => "enable",
        ) ),
)

cgi.assign = (
        ".pl"  => "/usr/bin/perl",
        ".cgi" => "/usr/bin/perl",
)

userdir.include-user = (
        "jan",
)
userdir.path = "/"

\$HTTP["host"] == "auth-htpasswd.example.org" {
        auth.backend = "htpasswd"
}

auth.backend = "plain"
auth.backend.plain.userfile = "/tmp/lighttpd/lighttpd.user"

auth.backend.htpasswd.userfile = "/tmp/lighttpd/lighttpd.htpasswd"

auth.require = (
        "/server-status" => (
                "method"  => "digest",
                "realm"   => "download archiv",
                "require" => "group=www|user=jan|host=192.168.2.10",
        ),
        "/server-config" => (
                "method"  => "basic",
                "realm"   => "download archiv",
                "require" => "valid-user",
        ),
)

url.access-deny = (
        "~",
        ".inc",
)

url.rewrite = (
        "^/rewrite/foo(\$|\?.+)" => "/indexfile/rewrite.php\$1",
        "^/rewrite/bar(?:\$|\?(.+))" => "/indexfile/rewrite.php?bar&\$1",
)

url.rewrite-if-not-file = (
        "^(/rewrite/[^?]*)(?:\?(.*))?\$" => "/indexfile/rewrite.php?file=\$1&\$2",
)

expire.url = (
        "/expire/access" => "access 2 hours",
        "/expire/modification" => "access plus 1 seconds 2 minutes",
)

#### status module
status.status-url = "/server-status"
status.config-url = "/server-config"

\$SERVER["socket"] == "10.0.0.234:443" {
  ssl.engine = "enable" 
  ssl.pemfile = "/etc/ssl/apache/initial/initial_librerouter_net.pem" 
}
EOF
}


# ---------------------------------------------------------
# Function to configure tahoe
# ---------------------------------------------------------
configure_tahoe()
{
/home/tahoe-lafs/venv/bin/tahoe stop /usr/node_1
/home/tahoe-lafs/venv/bin/tahoe stop /usr/public_node
rm -rf /usr/node_1
rm -rf /usr/public_node

# Sanity SSH keys
ssh-keygen -f "/root/.ssh/known_hosts" -R [localhost]:8022
ssh-keygen -f "/root/.ssh/known_hosts" -R [localhost]:8024


# Create private node
# Prepare random user/pass for mount this node
random_user=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-12})
random_pass=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-12})
echo "$random_user $random_pass" > /root/.tahoe/node_1

# Discover URI:DIR2 for the root
# This of course must be done AFTER the node is started and connected, so we will need
# to restart the node after update private/accounts

cd /home/tahoe-lafs 
nickname="liberouter_client1"
introducer="pb://hootxde72nklvu2de3n57a3szfkbazrd@tor:3h3ap6f4b62dvh3m.onion:3457/7jho3gaqpsarnvieg7iszqm7zsffvzic"

/home/tahoe-lafs/venv/bin/tahoe create-node --listen=tor --nickname=$nickname --introducer=$introducer --hide-ip --webport=tcp:3456:interface=127.0.0.1 --tor-launch /usr/node_1
cd /usr/node_1
echo "$random_user $random_pass FALSE" > private/accounts
cat <<EOT  | grep -v EOT>> tahoe.cfg
[sftpd]
enabled = true
port = tcp:8022:interface=127.0.0.1
host_pubkey_file = private/ssh_host_rsa_key.pub
host_privkey_file = private/ssh_host_rsa_key
accounts.file = private/accounts
EOT
echo "Generamos keys para node_1"
ssh-keygen -q -N '' -f private/ssh_host_rsa_key
mkdir /var/node_1


# Create public node ( common to all boxes ) with rw permisions

random_user=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-12})
random_pass=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-12})
echo "$random_user $random_pass" > /root/.tahoe/public_node

cd /home/tahoe-lafs
nickname=public
introducer="pb://hootxde72nklvu2de3n57a3szfkbazrd@tor:3h3ap6f4b62dvh3m.onion:3457/7jho3gaqpsarnvieg7iszqm7zsffvzic"
/home/tahoe-lafs/venv/bin/tahoe create-node --listen=tor --nickname=$nickname --introducer=$introducer --hide-ip --webport=tcp:9456:interface=127.0.0.1 --tor-launch /usr/public_node
cd /usr/public_node
echo "$random_user $random_pass FALSE" > private/accounts
cat <<EOT  | grep -v EOT>> tahoe.cfg
[sftpd]
enabled = true
port = tcp:8024:interface=127.0.0.1
host_pubkey_file = private/ssh_host_rsa_key.pub
host_privkey_file = private/ssh_host_rsa_key
accounts.file = private/accounts
EOT

ssh-keygen -q -N '' -f private/ssh_host_rsa_key
mkdir /var/public_node


# Now we need to start both nodes, to allow discoveing on URL:DIR2 for node_1
echo "Starting nodes to allow URL:DIR2 discovering for node_1" 
/home/tahoe-lafs/venv/bin/tahoe start /usr/node_1
/home/tahoe-lafs/venv/bin/tahoe start /usr/public_node
# this waiting time is required, otherwise sometimes nodes even started are not yet ready to create aliases and fails conneting with http with "500 Internal Server Error"
sleep 10;

connnode_1=0
connpubnod=0
while [ $connnode_1 -lt 7 ] || [ $connpubnod -lt 7 ]; do
connnode_1=$(curl http://127.0.0.1:3456/ 2> /dev/null| grep "Connected to tor" | wc -l)
connpubnod=$(curl http://127.0.0.1:9456/ 2> /dev/null| grep "Connected to tor" | wc -l)
echo "Node_1 cons: $connnode_1 P_node cons: $connpubnod"
done


# Extra check both nodes are OK and connected through Tor
# via tor: failed to connect: could not use config.SocksPort
connection_status_node_1=$(curl http://127.0.0.1:3456 | grep -v grep | grep "via tor: failed to connect: could not use config.SocksPort")
connection_status_public_node=$(curl http://127.0.0.1:9456 | grep -v grep | grep "via tor: failed to connect: could not use config.SocksPort")

if [ ${#connection_status_node_1} -gt 3 ] || [ ${#connection_status_public_node} -gt 3 ]; then 
   echo "Error: Can NOT connect to TOR. Please check tor configuration file. This is ussualy due to SocksPort 127.0.0.1:port, use just port "
   echo "Fix this issue, restart TOR and try again."
   exit;
fi

# Let's go to discover it
echo "Creating aliases for Tahoe..."
mkdir /root/.tahoe/private
/home/tahoe-lafs/venv/bin/tahoe create-alias -u http://127.0.0.1:3456 node_1:
# echo "Creating public_node alias for Tahoe..."
# /home/tahoe-lafs/venv/bin/tahoe create-alias -u http://127.0.0.1:9456 public_node:

echo "Fetching URL:DIR2 for node_1"
URI1=$(/home/tahoe-lafs/venv/bin/tahoe manifest -u http://127.0.0.1:3456 node_1: | head -n 1)
# URI2=$(/home/tahoe-lafs/venv/bin/tahoe manifest -u http://127.0.0.1:9456 public_node: | head -n 1)
echo "$URI1 fetched"

# Update the /private/accounts
echo -n $URI1 >> /usr/node_1/private/accounts
echo -n URI:DIR2:rjxappkitglshqppy6mzo3qori:nqvfdvuzpfbldd7zonjfjazzjcwomriak3ixinvsfrgua35y4qzq >> /usr/public_node/private/accounts
echo "public_node: URI:DIR2:rjxappkitglshqppy6mzo3qori:nqvfdvuzpfbldd7zonjfjazzjcwomriak3ixinvsfrgua35y4qzq" >> /root/.tahoe/private/aliases
updatednode_1=$(sed -e "s/FALSE/ /g" /usr/node_1/private/accounts )
updatedpubic_node=$(sed -e "s/FALSE/ /g" /usr/public_node/private/accounts )
echo $updatednode_1 > /usr/node_1/private/accounts
echo $updatedpubic_node > /usr/public_node/private/accounts

# Update offered space
new_tahoe_cfg=$(sed -e "s/reserved_space = 1G/reserved_space = 8G/g" /usr/node_1/tahoe.cfg)
# echo "$new_tahoe_cfg"
echo "$new_tahoe_cfg" > /usr/node_1/tahoe.cfg

# Done, now we can restart the nodes
/home/tahoe-lafs/venv/bin/tahoe  stop /usr/node_1
/home/tahoe-lafs/venv/bin/tahoe  stop /usr/public_node

# Now prepare start all nodes and mount points for next reboot
cat <<EOT  | grep -v EOT> /etc/init.d/start_tahoe
#!/bin/sh
### BEGIN INIT INFO
# Provides: librerouter_tahoe
# Required-Start: $syslog
# Required-Stop: $syslog
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: tahoe
# Description:
#
### END INIT INFO
# Start nodes
/home/tahoe-lafs/venv/bin/tahoe stop /usr/public_node
/home/tahoe-lafs/venv/bin/tahoe stop /usr/node_1
/home/tahoe-lafs/venv/bin/tahoe start /usr/public_node
/home/tahoe-lafs/venv/bin/tahoe start /usr/node_1
# Wait until enough connections on both nodes
# because if not enough storage nodes the upload will be placed on few nodes and this
# affects performance 
connnode_1=0
connpubnod=0
while [ \$connnode_1 -lt 7 ] || [ \$connpubnod -lt 7 ]; do
connnode_1=\$(curl http://127.0.0.1:3456/ 2> /dev/null| grep "Connected to tor" | wc -l)
connpubnod=\$(curl http://127.0.0.1:9456/ 2> /dev/null| grep "Connected to tor" | wc -l)
# echo "Node_1 cons: \$connnode_1 P_node cons: \$connpubnod"
done
# Mount points
if [ -e /root/.tahoe/node_1 ]; then
  umount /var/node_1
  user=\$(cat /root/.tahoe/node_1 | cut -d \  -f 1)
  pass=\$(cat /root/.tahoe/node_1 | cut -d \  -f 2)
  echo \$pass | sshfs \$user@127.0.0.1:  /var/node_1  -p 8022 -o no_check_root -o password_stdin
fi
if [ -e /root/.tahoe/public_node ]; then
  umount /var/public_node
  user=\$(cat /root/.tahoe/public_node | cut -d \  -f 1)
  pass=\$(cat /root/.tahoe/public_node | cut -d \  -f 2)
  echo \$pass | sshfs \$user@127.0.0.1:  /var/public_node  -p 8024 -o no_check_root -o password_stdin
fi
echo 0 > /var/run/backup
EOT

chmod u+x /etc/init.d/start_tahoe
update-rc.d start_tahoe defaults


# Creamos /root/start_backup.sh
# This script will be check if no any other instance of backup is running
# Then will compress predefined directories and files into tar.gz sys backup file
# Then compare with actual backup contents and do a serialization of backups up to N 
# As default N=1 while Tahoe does 3/7/10 or better, otherwise to do more serialization more shared space would be required
cat <<EOT  | grep -v EOT> /root/start_backup.sh
# Do not allow more than one instance
sem=$(cat /var/run/backup)
if [ \$sem -gt 0 ]; then
  exit
fi
echo 1 > /var/run/backup
# Create a /tmp/sys.backup.tar.gz
rm -f /tmp/sys.backup.tar.gz
tar  --exclude=*passwd* --exclude=*shadow* --exclude=hostapd* --exclude=networks -cpPf /tmp/sys.backup.tar /etc
tar  --exclude=bin --exclude=node_1 --exclude=public_node -rpPf /tmp/sys.backup.tar /usr
tar -rpPf /tmp/sys.backup.tar /var/www
tar -rpPf /tmp/sys.backup.tar /var/lib/mysql
gzip /tmp/sys.backup.tar
/home/tahoe-lafs/venv/bin/tahoe cp -u http://127.0.0.1:3456 /tmp/sys.backup.tar.gz node_1:
echo 0 > /var/run/backup
EOT
chmod u+x /root/start_backup.sh


# Now are going to insert into cron a call for the sys backup
if [ ! $(cat /var/spool/cron/crontabs/root | grep start_backup) ] 2>/dev/null ; then
    echo "0 0 * * mon /root/start_backup.sh" >> /var/spool/cron/crontabs/root
fi
}


# ---------------------------------------------------------
# Function to configure tahoe 2
# ---------------------------------------------------------
configure_tahoe2()
{
# Will create /root/libre_scripts/id_tahoe.sh to be called ONCE only 
# through ton next reboot or manually from the wizard.sh
#

cat <<EOT | grep -v EOT> /root/libre_scripts/id_tahoe.sh
# will prompt user for ALIAS name and PASSWORD on clean installation.
# This clean ALIAS will be saved to Public tahoe area with contents an encrypted string
# The decrypted string will point to the Private tahoe area for this box
#
# This script must be launched AFTER app_install_tahoe.sh and AFTER app_start_tahoe.sh
# if NEW_INSTALL as part of APP_CONFIGURATION_SCRIPT.
#
# This script is the light green area on the flow drawing

#if [ -f /tmp/.X0-lock ];
#then
#Dialog=Xdialog
#else
#Dialog=dialog
#fi

# This user interface will detect the enviroment and will chose a method based
# on this order : X no GTK, X with GTK , dialaog, none )

interface=0
if [ -x n/usr/bin/dialog ] || [ -x n/bin/dialog ]; then
    interface=dialog
else 
    inteface=none
    if [ -f /tmp/.X0-lock ]; then
        interface=X
        if [ -x /usr/bin/gtk]; then
            inteface=Xdialog
        fi
    fi
fi



prompt() {

textmsg="Enter some easy to remember ID here. \nThis will be used in case you need to recover your full system configuration from backup\n\
This id may be public visible\n\n\
Use an enough hard password with minimum 8 bytes and write down in a safe place.\n\n";

if [ \${#errmsg} -gt 0 ]; then
    color='\033[0;31m'
    nocolor='\033[0m'
    textmsg="\${nocolor}$textmsg ${color} $errmsg"
    errmsg=""
fi



if [ \$interface = "dialog" ]; then

dialog --colors --form "\$textmsg" 0 0 3 "Enter your alias:" 1 2 "\$myalias"  1 20 20 20 "Passwod:" 2 2 "" 2 20 20 20 "Repeat Password:" 3 2 "" 3 20 20 20 2> /tmp/inputbox.tmp

credentials=\$(cat /tmp/inputbox.tmp)
rm /tmp/inputbox.tmp
thiscounter=0
local IFS='
'
for lines in \$credentials; do
#while IFS= read -r lines; do
    if [ \$thiscounter = "0" ]; then 
        myalias="\$lines"
    fi
    if [ \$thiscounter = "1" ]; then 
        myfirstpass="\$lines"
    fi
    if [ $thiscounter = "2" ]; then 
        mysecondpass="\$lines"
    fi
    ((thiscounter++));    
done 

else
echo -e \$textmsg\${nocolor}
# echo -e "Enter some easy to remember ID here. \nThis will be used in case you need to recover your full system configuration from backup\nThis id may be public visible\n\n"
read -p "What is your username? " -e myalias

echo -e "Use an enough hard password with minimum 8 bytes and write down in a safe place.\n\n"
read -p "Passwod:" -e myfirstpass

read -p "Repeat Passwod:" -e mysecondpass

fi


}


check_inputs() {

errmsg="";
# Are valid all these inputs ?
if [ -z "\${myalias##*" "*}" ]; then
    errmsg="Spaces are not allowed";
fi

strleng=\${#myalias}
if [[ \$strleng -lt 8 ]]; then
    errmsg="\$myalias \${#myalias} Must be at least 8 characters long"
fi

if [ -z "\${myfirstpass##*" "*}" ]; then
    errmsg="Spaces are not allowed";
fi

strleng=\${#myfirstpass}
if [[ \$strleng -lt 8 ]]; then
    errmsg="\$myfirstpass \${#myalias} Must be at least 8 characters long"
fi

if [ \$myfirstpass != \$mysecondpass ]; then
    errmsg="Please repeat same password"
fi

while [ \${#errmsg} -gt 0 ]; do
    echo "ERROR: \$errmsg\$errmsg2"
    prompt
    check_inputs
done
  
}


ofuscate () {
    thiscounter=0
    output=''
    while [ \$thiscounter -lt 30 ]; do
        ofuscated=\$ofuscated\${myalias:\$thiscounter:1}\$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c\${1:-4})
        ((thiscounter++));
    done
}


/etc/init.d/start_tahoe
prompt
check_inputs

# Convert this alias to encrypted key with pass=$myfirstpass and save as $myalias

# creates PEM 
rm /tmp/ssh_keys*
ssh-keygen -N \$myfirstpass -f /tmp/ssh_keys 2> /dev/null
openssl rsa  -passin pass:\$myfirstpass -outform PEM  -in /tmp/ssh_keys -pubout > /tmp/rsa.pem.pub

# create a key phrase for the private backup Tahoe node config and upload to public/$myalias file
# the $phrase is the entry point to the private area (pb:/ from /usr/node_1/tahoe.cfg )
# $phrase will be like "user pass URI:DIR2:guq3z6e68pf2bvwe6vdouxjptm:d2mvquow4mxoaevorf236cjajkid5ypg2dgti4t3wgcbunfway2a"
#frase=$(/home/tahoe-lafs/venv/bin/tahoe manifest -u http://127.0.0.1:3456 node_1: | head -n 1)
frase=\$(cat /usr/node_1/private/accounts | head -n 1)
echo \$frase | openssl rsautl -encrypt -pubin -inkey /tmp/rsa.pem.pub  -ssl > /tmp/\$myalias
mv /tmp/\$myalias /var/public_node/\$myalias
ofuscate
cp /tmp/ssh_keys  /var/public_node/.keys/\$ofuscated


# Decrypt will be used for restore only, and will discover the requied URI:DIR2 value for the private area node
# cat /var/public_node/$myalias | openssl rsautl -decrypt -inkey /tmp/ssh_keys # < Will prompt for password to decrypt it
EOT

}


# ---------------------------------------------------------
# Function to redirect yacy and prosody traffic to tor
# ---------------------------------------------------------
services_to_tor()
{
# Define a control group for the net_cls controller
mkdir /sys/fs/cgroup/net_cls/new_route
#cd /sys/fs/cgroup/net_cls/new_route
echo 0x00110011 > /sys/fs/cgroup/net_cls/new_route/net_cls.classid

# Use iptables to fwmark packets
iptables -t mangle -A OUTPUT -m cgroup --cgroup 0x00110011 -j MARK --set-mark 1

# Declare an additional routing table for policy routing
echo 11 new_route >> /etc/iproute2/rt_tables 
ip rule add fwmark 11 table new_route
ip route add default via 10.0.10.58 table new_route

# Find PID of Yacy 
YACY_PID=ps aux | grep yacy | grep /usr/bin/java | awk '{print $2}'
#cd /sys/fs/cgroup/net_cls/new_route
echo $YACY_PID > /sys/fs/cgroup/net_cls/new_route/tasks
}


# ---------------------------------------------------------
# Function to configure defense against ARP Spoofing
# ---------------------------------------------------------
configure_arp()
{
echo "Configuring arp security ..." | tee -a /var/libre_config.log

# configuring hosts
echo "
order hosts,bind
multi on
nospoof on
spoofalert on
" > /etc/host.conf

# Turn on Source Address Verification in all interfaces to prevent some spoofing attacks.
echo 1 > /proc/sys/net/ipv4/conf/all/rp_filter
echo 1 > /proc/sys/net/ipv4/conf/default/rp_filter

# Disables TCP Window Scaling.
echo 1 > /proc/sys/net/ipv4/tcp_syncookies

# Do not accept ICMP redirects.
echo 0 > /proc/sys/net/ipv4/conf/all/accept_redirects
echo 0 > /proc/sys/net/ipv4/conf/default/accept_redirects

# Ignore ICMP broadcasts will stop gateway from responding to broadcast pings.
echo 1 > /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts

# Ignore bogus ICMP errors.
echo 1 > /proc/sys/net/ipv4/icmp_ignore_bogus_error_responses

# Do not send ICMP redirects.
echo 0 > /proc/sys/net/ipv4/conf/all/send_redirects
echo 0 > /proc/sys/net/ipv4/conf/default/send_redirects

# Do not accept IP source route packets.
echo 0 > /proc/sys/net/ipv4/conf/all/accept_source_route
echo 0 > /proc/sys/net/ipv4/conf/default/accept_source_route

# Turn on log Martian Packets with impossible addresses.
echo 1 > /proc/sys/net/ipv4/conf/all/log_martians
echo 1 > /proc/sys/net/ipv4/conf/default/log_martians

# Provide IP restrictions based on the client MAC address.
HWADDR=`arp $CGWIP | grep $CGWIP | awk '{print $3}'`
arp -s $CGWIP $HWADDR

# Blocking Historical Broadcasts.
iptables -A INPUT -j DROP -s 0.0.0.0/8
iptables -A INPUT -j DROP -d 0.0.0.0/8
iptables -A FORWARD -j DROP -s 0.0.0.0/8
iptables -A FORWARD -j DROP -d 0.0.0.0/8
iptables -A OUTPUT -j DROP -d 0.0.0.0/8
}

configure_nxfilter()
{

echo "Configuring nxfilter ..." | tee -a /var/libre_config.log
cp /opt/nxfilter/conf/cfg.default /opt/nxfilter/conf/cfg.properties
sed -i "s/0.0.0.0/10.0.0.2/g" /opt/nxfilter/conf/cfg.properties

cd /opt/nxfilter
if [ -d /db ] ; then
   rm -R ./db
fi
mkdir db
mv config.h2.db ./db/
chmod 755 /opt/nxfilter/bin/startup.sh
chmod 755 /opt/nxfilter/bin/shutdown.sh

## we add to categories.txt and to baselist.txt domains filtered by unbound
num_cat=`cat ./jahaslist/categories.txt | tail -n1 | tr ';' ' ' | awk '{print $1}'`
num_cat=`expr $num_cat + 1`

for x in `cat /etc/unbound/block_domain.list.conf | awk '{print $2}' | tr '"' ' '`
  do
        echo "$x,$num_cat" >> /opt/nxfilter/jahaslist/baselist.txt
  done

echo " " >> /opt/nxfilter/jahaslist/categories.txt
echo "$num_cat;BlockedUnbound; unbound blacklist." >> /opt/nxfilter/jahaslist/categories.txt

## we adjust max of 256My of RAM to nxfilter
sed -i "s/-Xmx512m/-Xmx256m/g" /opt/nxfilter/bin/startup.sh
sed -i "/exit 0/d" /etc/rc.local
echo "/opt/nxfilter/bin/startup.sh -d &" >> /etc/rc.local
echo "exit 0" >> /etc/rc.local

echo "/opt/nxfilter/bin/shutdown.sh" >> /etc/init.d/halt
echo "/opt/nxfilter/bin/shutdown.sh" >> /etc/init.d/reboot

echo "configuring nxfilter as dns server" | tee -a /var/libre_config.log
# chattr -i /etc/resolv.conf
# echo "nameserver 10.0.0.2" > /etc/resolv.conf
# chattr +i /etc/resolv.conf

}

updating_MX_domain()
{
cat <<EOT | grep -v EOT> /root/libre_scripts/mx_filter.sh
# we make the initial backup if it doesn't exist
if [ ! -d /etc/unbound/backup ] ; then
    mkdir /etc/unbound/backup
    for file in storage_domain.list.conf chat_domain.list.conf socialnet_domain.list.conf webmail_domain.list.conf
       do
          cp /etc/unbound/$file /etc/unbound/backup/$file
       done
  fi

## changing dns
chattr -i /etc/resolv.conf
echo "nameserver 8.8.8.8" > /etc/resolv.conf

## restarting initial files to add again MX entries
cp /etc/unbound/backup/*.conf /etc/unbound/

echo "starting updating MX domains, this is a long process..."
echo "it will last more than 3 hours"

## changing /etc/unbound/*.conf
for file in `ls /etc/unbound/backup`
 do
   echo "adding MX entries to $file" | tee -a /var/libre_config.log
   for domain in `cat /etc/unbound/$file | grep local-data | awk '{print $2}' | tr "\"" " " `
     do
        echo "local-data: \"$domain IN A 10.0.0.254\"" >> /etc/unbound/new.$file
        nslookup -type=mx $domain | grep "mail exchanger" > /etc/unbound/temp.txt
          while read chain 
          do 
            name=`echo $chain | awk '{print $6}'` 
            num=`echo $chain | grep $name | awk '{print $5}'`
            echo "local-data: \"$domain IN MX $num $name\"" >> /etc/unbound/new.$file  
          done < /etc/unbound/temp.txt 
     done
 done
rm /etc/unbound/temp.txt

echo "updated MX entries successfully and cleaning files" | tee -a /var/libre_config.log
for file in `ls /etc/unbound/backup`
  do
    mv /etc/unbound/new.$file /etc/unbound/$file
  done

# echo "nameserver 10.0.0.2" > /etc/resolv.conf
# chattr +i /etc/resolv.conf

echo "updated MX entries and restarting unbound"
/etc/init.d/unbound restart

}

EOT


chmod u+x /root/libre_scripts/mx_filter.sh
echo "0 1 1 1 * /root/libre_scripts/mx_filter.sh " >> /var/spool/cron/crontabs/root
echo "root/libre_scripts/mx_filter.sh" > /root/libre_scripts/mx_filter_first_boot.sh
echo "chattr -i /etc/resolv.conf" >> root/libre_scripts/mx_filter_first_boot.sh
echo "echo \"nameserver 10.0.0.2\" > /etc/resolv.conf" >> /root/libre_scripts/mx_filter_first_boot.sh
echo "chattr +i /etc/resolv.conf" >> root/libre_scripts/mx_filter_first_boot.sh
echo "rm root/libre_scripts/mx_filter_first_boot.sh" >> /root/libre_scripts/mx_filter_first_boot.sh
chmod u+x /root/libre_scripts/mx_filter_first_boot.sh
echo "if [ -e /root/libre_scripts/mx_filter_first_boot.sh];then" >> /etc/rc.local
echo "   /root/libre_scripts/mx_filter_first_boot.sh" >> /etc/rc.local
echo "fi" >> /etc/rc.local



# ---------------------------------------------------------
# Function to add warning pages for clamav and squidguard
# ---------------------------------------------------------
add_warning_pages()
{
echo "Configuring warning pages ..." | tee -a /var/libre_config.log
# Warning page for clamav
cat << EOF > /var/www/html/virus_warning_page.html
<!DOCTYPE html>
<html>
<head>
<style>
div.container {
width: 100%;
border: 1px solid red;
}
header, footer {
padding: 1em;
color: white;
background-color: red;
clear: left;
text-align: center;
}
article {
margin-left: 170px;
border-left: 1px solid red;
padding: 1em;
overflow: hidden;
}
</style>
</head>
<body>
<div class="container">
<header>
<h1>WARNING !!!</h1>
</header>
<article>
<h1>Visiting this site may harm your computer</h1>
<p>The website you are visiting appears to host malware - software that can hurt your computer or otherwise operate without your consent.</p>
<p>Just visiting a site that contains malware can infect your computer.</p>
</article>
<footer>LibreRouter</footer>
</div>
</body>
</html>
EOF

# Warning page for squidguard
cat << EOF > /var/www/html/squidguard_warning_page.html
<!DOCTYPE html>
<html>
<head>
<style>
div.container {
width: 100%;
border: 1px solid red;
}
header, footer {
padding: 1em;
color: white;
background-color: red;
clear: left;
text-align: center;
}
article {
margin-left: 170px;
border-left: 1px solid red;
padding: 1em;
overflow: hidden;
}
</style>
</head>
<body>
<div class="container">
<header>
<h1>WARNING !!!</h1>
</header>
<article>
<h1>Security risk blocked for your protection</h1>
<p>The website category is filtered.</p>
<p>Access to the web page you were trying to visit has been blocked in accordance with security policy.</p>
</article>
<footer>LibreRouter</footer>
</div>
</body>
</html>
EOF

# Add default page for not enabled services
cat << EOF > /var/www/html/index.html
<!DOCTYPE html>
<html>
<head>
<style>
div.container {
width: 100%;
border: 1px solid green;
}
header, footer {
padding: 1em;
color: white;
background-color: green;
clear: left;
text-align: center;
}
article {
margin-left: 170px;
border-left: 1px solid green;
padding: 1em;
overflow: hidden;
}
</style>
</head>
<body>
<div class="container">
<header>
<h1>SERVICE NOT FOUND !!!</h1>
</header>
<article>
<h1>Please check if service you are looking for is enabled.</h1>
<p></p>
<p></p>
</article>
<footer>LibreRouter</footer>
</div>
</body>
</html>
EOF
}


# ---------------------------------------------------------
# Function to print info about services accessibility
# ---------------------------------------------------------
print_services()
{
rm -rf /var/box_services
touch /var/box_services
echo "Printing local services info ..." | tee -a /var/libre_config.log
echo ""
echo "-------------------------------------------------------------------------------------" \
| tee /var/box_services
echo "| Service Name |       Tor domain       |       Direct access        |  IP Address  |" \
| tee -a /var/box_services
echo "-------------------------------------------------------------------------------------" \
| tee -a /var/box_services
for i in $(ls /var/lib/tor/hidden_service/)
do
if [ $i == "easyrtc" ]; then
IP_ADD="10.0.0.250"
hn="$(cat /var/lib/tor/hidden_service/$i/hostname 2>/dev/null )"
printf "|%12s  |%23s | conference.librerouter.net |%13s |\n" $i $hn $IP_ADD \
| tee -a /var/box_services
fi

if [ $i == "yacy" ]; then
IP_ADD="10.0.0.251"
hn="$(cat /var/lib/tor/hidden_service/$i/hostname 2>/dev/null )"
printf "|%12s  |%23s |     search.librerouter.net |%13s |\n" $i $hn $IP_ADD \
| tee -a /var/box_services
fi

if [ $i == "friendica" ]; then
IP_ADD="10.0.0.252"
hn="$(cat /var/lib/tor/hidden_service/$i/hostname 2>/dev/null )"
printf "|%12s  |%23s |     social.librerouter.net |%13s |\n" $i $hn $IP_ADD \
| tee -a /var/box_services
fi

if [ $i == "nextcloud" ]; then
IP_ADD="10.0.0.253"
hn="$(cat /var/lib/tor/hidden_service/$i/hostname 2>/dev/null )"
printf "|%12s  |%23s |    storage.librerouter.net |%13s |\n" $i $hn $IP_ADD \
| tee -a /var/box_services
fi

if [ $i == "mailpile" ]; then
IP_ADD="10.0.0.254"
hn="$(cat /var/lib/tor/hidden_service/$i/hostname 2>/dev/null )"
printf "|%12s  |%23s |      email.librerouter.net |%13s |\n" $i $hn $IP_ADD \
| tee -a /var/box_services
fi

if [ $i == "ssh" ]; then
IP_ADD="10.0.0.1"
hn="$(cat /var/lib/tor/hidden_service/$i/hostname 2>/dev/null )"
printf "|%12s  |%23s |%18s.librenet |%13s |\n" $i $hn $i $IP_ADD \
| tee -a /var/box_services
fi

if [ $i == "gitlab" ]; then
IP_ADD="10.0.0.247"
hn="$(cat /var/lib/tor/hidden_service/$i/hostname 2>/dev/null )"
printf "|%12s  |%23s |     gitlab.librerouter.net |%13s |\n" $i $hn $IP_ADD \
| tee -a /var/box_services
fi

if [ $i == "trac" ]; then
IP_ADD="10.0.0.248"
hn="$(cat /var/lib/tor/hidden_service/$i/hostname 2>/dev/null )"
printf "|%12s  |%23s |       trac.librerouter.net |%13s |\n" $i $hn $IP_ADD \
| tee -a /var/box_services
fi

if [ $i == "redmine" ]; then
IP_ADD="10.0.0.249"
hn="$(cat /var/lib/tor/hidden_service/$i/hostname 2>/dev/null )"
printf "|%12s  |%23s |    redmine.librerouter.net |%13s |\n" $i $hn $IP_ADD \
| tee -a /var/box_services
fi

if [ $i == "roundcube" ]; then
IP_ADD="10.0.0.243"
hn="$(cat /var/lib/tor/hidden_service/$i/hostname 2>/dev/null )"
printf "|%12s  |%23s |  roundcube.librerouter.net |%13s |\n" $i $hn $IP_ADD \
| tee -a /var/box_services
fi


#hn="$(cat /var/lib/tor/hidden_service/$i/hostname 2>/dev/null )"
#printf "|%12s  |%23s |%18s.librenet |%13s |\n" $i $hn $i $IP_ADD \
#| tee -a /var/box_services

done
echo "|  squidguard  |                        | squidguard.librerouter.net |   10.0.0.246 |" \
| tee -a /var/box_services
echo "|      webmin  |                        |     webmin.librerouter.net |   10.0.0.245 |" \
| tee -a /var/box_services
echo "|        ntop  |                        |       ntop.librerouter.net |   10.0.0.244 |" \
| tee -a /var/box_services
echo "|     postfix  |                        |    postfix.librerouter.net |   10.0.0.242 |" \
| tee -a /var/box_services
echo "|        sogo  |                        |       sogo.librerouter.net |   10.0.0.241 |" \
| tee -a /var/box_services
echo "|      snorby  |                        |     snorby.librerouter.net |   10.0.0.239 |" \
| tee -a /var/box_services
echo "|      waffle  |                        |     waffle.librerouter.net |   10.0.0.238 |" \
| tee -a /var/box_services
echo "|  webconsole  |                        | webconsole.librerouter.net |   10.0.0.237 |" \
| tee -a /var/box_services
echo "|         gui  |                        |        gui.librerouter.net |   10.0.0.236 |" \
| tee -a /var/box_services
echo "|         dns  |                        |        dns.librerouter.net |   10.0.0.235 |" \
| tee -a /var/box_services
echo "|     initial  |                        |    initial.librerouter.net |   10.0.0.234 |" \
| tee -a /var/box_services

echo "------------------------------------------------------------------------------------" \
| tee -a /var/box_services

# Print i2p
echo "" | tee -a /var/box_services
echo "------------------------------------------------------------------------------" | tee -a /var/box_services
echo "| Service     |                         i2p domain                           |" | tee -a /var/box_services
echo "------------------------------------------------------------------------------" | tee -a /var/box_services
echo -n "| conference   | " | tee -a /var/box_services
echo -n $I2P_CONFERENCE | tee -a /var/box_services
echo " |" | tee -a /var/box_services
echo -n "| search       | " | tee -a /var/box_services
echo -n $I2P_SEARCH     | tee -a /var/box_services
echo " |" | tee -a /var/box_services
echo -n "| social       | " | tee -a /var/box_services
echo -n $I2P_SOCIAL     | tee -a /var/box_services
echo " |" | tee -a /var/box_services
echo -n "| storage      | " | tee -a /var/box_services
echo -n $I2P_STORAGE    | tee -a /var/box_services
echo " |" | tee -a /var/box_services
echo -n "| email        | " | tee -a /var/box_services
echo -n $I2P_EMAIL      | tee -a /var/box_services
echo " |" | tee -a /var/box_services
echo -n "| gitlab      | " | tee -a /var/box_services
echo -n $I2P_GITLAB    | tee -a /var/box_services
echo " |" | tee -a /var/box_services
echo -n "| trac        | " | tee -a /var/box_services
echo -n $I2P_TRAC      | tee -a /var/box_services
echo " |" | tee -a /var/box_services
echo -n "| redmine     | " | tee -a /var/box_services
echo -n $I2P_REDMINE   | tee -a /var/box_services
echo " |" | tee -a /var/box_services
echo "------------------------------------------------------------------------------" | tee -a /var/box_services

cat << EOF >> /var/box_services

------------------------------------------------------------------------------
|                  Users and Passwords in LibreRouter                        |
------------------------------------------------------------------------------
|    services name    |        username        |        password             |
------------------------------------------------------------------------------
|    mysql            |          root          |       $MYSQL_PASS            |
|    postfix          |          admin         |       $POSTFIX_PASS            |
|    roundcube        |      (Please Register mailbox in postfix)            |
|    conference       |                    (No Need)                         |
|    gui              |                    (No Need)                         |
|    social           |                (Please Register)                     |
|    gitlab           |                (Please Register)                     |
|    email            |                (Please Register)                     |
|    storage          |          admin         |       $CLOUD_PASS            |
|    redmine          |                (Please Register)                     |
|    dns              |          admin         |       admin                 |
|    trac             |          admin         |       $TRAC_PASS            |
|    search           |          admin         |       $YACY_PASS            |
|    ssh              |         (Your machine root login and pass)           |
|    webmin           |         (Your machine root login and pass)           |
|    sogo             |                                                      |
|    snorby           | admin@librerouter.net  |       $SNORBY_PASS            |
|    webconsole       |         web            |       $WEB_PASS            |  
------------------------------------------------------------------------------
EOF

# Create services command
cat << EOF > /usr/sbin/services
#!/bin/bash
key=\$1
  case \$key in
    -p|--print)
      cat /var/box_services
      ;;
    -w|--wlan)
      /root/libre_scripts/apmode.sh
      ;;
    -h|--help|*)
      echo ""
      echo "    Usage: services  [OPTION]"
      echo ""
      echo "    -p   print servicese information"
      echo "    -w   run wlan AP configuration"
      echo "    -h   print help"
      echo ""
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
EOF

chmod +x /usr/sbin/services

echo "You can print local services info by \"services\" command"
sleep 2
}


# ---------------------------------------------------------
# Function to create configs and logs commands
# ---------------------------------------------------------
create_commands()
{
echo "Creating configs and logs commands" | tee -a /var/libre_config.log
cat << EOF > /var/box_configs
apache2          /etc/apache2/apache2.conf
prosody          /etc/prosody/prosody.cfg.lua
roundcube        /etc/roundcube/config.inc.php
spamassassin     /etc/spamassassin/local.cf
squid            /etc/squid/squid.conf
                 /etc/squid/squid-i2p.conf
                 /etc/squid/squid-tor.conf
squidclamav      /etc/squidclamav.conf
squidguard       /etc/squidguard/squidGuard.conf
ssh              /etc/ssh/sshd_config
                 /etc/ssh/ssh_config
dovecot          /etc/dovecot/dovecot.conf
ecapguardian     /etc/ecapguardian/ecapguardian.conf
elasticsearch    /etc/elasticsearch/elasticsearch.yml
mysql            /etc/mysql/my.cnf
ntopng           /etc/ntopng/ntopng.conf
gitlab           /etc/gitlab/gitlab.rb
tinyproxy        /etc/tinyproxy.conf
tomcat7          /etc/tomcat7/server.xml
postfix          /etc/postfix/main.cf
                 /etc/postfix/master.cf
postfixadmin     /etc/postfixadmin/config.inc.php
i2p              /etc/i2p/wrapper.config
privoxy          /etc/privoxy/config
                 /etc/privoxy/config-tor
yacy             /etc/yacy/yacy.conf
tor              /etc/tor/torrc
friendice        /var/www/friendica/htconfig.php
nextcloud        /var/www/nextcloud/config/config.php
mailpile         /opt/Mailpile/setup.cfg
redmine          /opt/redmine/redmine-3.3.1/config/configuration.yml
trac             /opt/trac/libretrac/conf/trac.ini
fail2ban	 /etc/fail2ban/fail2ban.conf
		 /etc/fail2ban/jail.conf
EOF

# Create configs command
cat << EOF > /usr/sbin/configs
#!/bin/bash
cat /var/box_configs
EOF
chmod +x /usr/sbin/configs


cat << EOF > /var/box_logs
apache2          /var/log/apache2/access.log
		 /var/log/apache2/error.log
prosody          /var/log/prosody/prosody.log
		 /var/log/prosody/prosody.err
roundcube        /var/log/roundcube_access.log
		 /var/log/roundcube_error.log
spamassassin     /var/log/syslog
squid            /var/log/squid/access.log
		 /var/log/squid/cache.log
squidclamav      /var/log/clamav/clamav.log
squidguard       /var/log/squidguard/squidGuard.log
ssh              /var/log/syslog
dovecot          /var/log/syslog
ecapguardian     /var/log/ecapguardian/access.log
elasticsearch    /var/log/syslog
mysql            /var/log/mysql.log
		 /var/log/mysql.err	
ntopng           /var/log/ntopng/ntopng.log
gitlab           /var/log/gitlab/*
tinyproxy        /var/log/tinyproxy/tinyproxy.log
tomcat7          /var/log/tomcat7/*
postfix          /var/log/postfix_access.log
		 /var/log/postfix_error.log
postfixadmin     /var/log/syslog
i2p	         /var/log/i2p/log-router-0.txt
		 /var/log/i2p/wrapper.log
privoxy 	 /var/log/privoxy/logfile
yacy		 /var/log/yacy/queries.log
		 /var/log/yacy/yacy00.log
tor		 /var/log/tor/log
friendica	 /var/log/apache/friendica.log
nextcloud        /var/log/apache/nextcloud.log
mailpile         /var/log/apache/mailpile.log
redmine          /var/log/apache/redmine.log
trac             /var/log/apache/trac.log
EOF

# Create logs command
cat << EOF > /usr/sbin/logs
#!/bin/bash
cat /var/box_logs
EOF
chmod +x /usr/sbin/logs

echo "You can print librerouter configuration and log files info by \"configs\" and \"logs\" commands"
sleep 2
}


# ---------------------------------------------------------
# Function to reboot librerouter
# ---------------------------------------------------------
do_reboot()
{
echo "Configuration finished !!!" | tee -a /var/libre_config.log
echo "Librerouter needs to restart. Restarting ..." | tee -a /var/libre_config.log
shutdown -r +1 &
#reboot

#echo "Librerouter needs to restart. Do restart now? [Y/N]"
#LOOP_N=0
#while [ $LOOP_N -eq 0 ]; do
#read ANSWER
#if [ "$ANSWER" = "Y" -o "$ANSWER" = "y" ]; then
#LOOP_N=1
#echo "Restarting ..."
#reboot
#elif [ "$ANSWER" = "N" -o "$ANSWER" = "n" ]; then
#LOOP_N=1
#echo "Exiting ..."
#else
#LOOP_N=0
#echo "Please type \"Y\" or \"N\""
#fi
#done
}

remove_console_blanking() {
  n_kbd=$(cat /etc/init.d/kbd | sed -e "s/\#\!\/bin\/sh/\#\!\/bin\/sh\nBLANK_TIME=\"0\"\nPOWERDOWN_TIME=\"0\"\nBLANK_DPMS=\"0\"/")
  echo "$n_kbd" > /etc/init.d/kbd
  update-rc.d kbd defaults
}




# ---------------------------------------------------------
# ************************ MAIN ***************************
# This is the main function on this script
# ---------------------------------------------------------

# Block 1: Configuing Network Interfaces

check_root			# Checking user
#get_variables			# Getting variables
get_platform			# Getting platform info
get_hardware			# Getting hardware info
get_interfaces          	# Get external and internal interfaces
get_hdd				# Getting hdd info
configure_hosts			# Configuring hostname and /etc/hosts
#configure_bridges		# Configure bridges
configure_interfaces		# Configuring external and internal interfaces
configure_reboot		# Configuring Reboot (Disabling Keyboard reboot, ctrl+alt+del)
configure_dhcp			# Configuring DHCP server 


# Block 2: Configuring services

configure_mysql			# Configuring mysql password
configure_banks_access		# Configuring banks access
configure_iptables		# Configuring iptables rules
configure_ssh			# Configuring ssh server
configure_tor			# Configuring TOR server
configure_i2pd			# Configuring i2pd services
configure_unbound		# Configuring Unbound DNS server
configure_dnscrypt		# Configuring DNSCrypt server
configure_yacy			# Configuring yacy search engine
configure_friendica		# Configuring Friendica local service
configure_easyrtc		# Configuring EasyRTC local service
configure_nextcloud		# Configuring Nextcloud local service
configure_mailpile		# Configuring Mailpile local service
configure_modsecurity		# Configuring modsecurity 
configure_waffle		# Configuring modsecurity GUI WAF-FLE
configure_privoxy		# Configuring Privoxy proxy server
configure_tinyproxy             # Configuring Tinyproxy proxy server
configure_squid			# Configuring squid proxy server
configure_c_icap		# Configuring c-icap daemon
configure_squidclamav		# Configuring squidclamav service
configure_squidguard		# Configuring squidguard
configure_squidguardmgr		# Configuring squidguardmgr
configure_ecapguardian		# Configuring ecapguardian
configure_fail2ban		# Configuring Fail2Ban

# ------ Mail server Config ------

configure_postfix		# Configuring postfix mail service
configure_postfixadmin		# Configuring postfixadmin service
configure_dovecot               # Configuring dovecot imap service
configure_amavis                # Configuring amavis service
configure_spamassasin           # Configuring spamassasin service
configure_roundcube		# Configuring Roundcube service

# --------------------------------

configure_trac			# Configuring trac service
configure_redmine		# Configuring redmine service
configure_webmin                # Configuring webmin service
configure_ntopng		# Configuring ntop service
configure_redsocks		# Configuring redsocks proxy server
configure_prosody		# Configuring prosody xmpp server 
configure_tomcat		# Configuring tomcat server
configure_apache		# Configuring apache web server
check_interfaces		# Checking network interfaces
check_services			# Checking services 
configure_suricata		# Configure Suricata service
configure_logstash		# Configure logstash
#configure_kibana		# Configure Kibana service
configure_gitlab 		# Configure gitlab servies (only for amd64)
configure_snorby		# Configure Snorby
configure_upnp                  # configure miniupnp
configure_webconsole            # configure webconsole service
configure_mat                   # configure mat (Metadata Anonymisation Toolkit)
configure_lighttpd              # configure lighttpd server

#configure_tahoe		# Configure tahoe
#configure_tahoe2               # Configure tahoe 2
#services_to_tor                # Redirect yacy and prosody traffic to tor
configure_arp			# Function to configure defense against ARP Spoofing
add_warning_pages		# Added warning pages for clamav and squidguard
configure_nxfilter              # Configure NxFilter DNS service 
updating_MX_domain              # adding MX entries to unbound
print_services			# Print info about service accessibility
create_commands                 # Create configs and logs commands
remove_console_blanking         # Force console blanking and power save=0
do_reboot                       # Function to reboot librerouter

#configure_blacklists		# Configuring blacklist to block some ip addresses


