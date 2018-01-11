#!/bin/bash
# ---------------------------------------------------------
#
# Installation script for Librerouter Module 2 
#
# Version: 1.0
# Author:  Librerouter Team
# ---------------------------------------------------------



# ----------------------------------------------
# check_root
# ----------------------------------------------
check_root()
{
        echo "`date +%s` Checking user root ..." | tee -a /var/libre_install.log
        if [ "$(whoami)" != "root" ]; then
                echo "`date +%s` You need to be root to proceed. Exiting" | tee -a /var/libre_install.log
                exit 2
        fi
}


# ----------------------------------------------
# check_internet
# ----------------------------------------------
check_internet()
{
        # Removing firewall
        iptables -F 
        iptables -t nat -F 
        iptables -t mangle -F

        echo "`date +%s` Checking Internet access ..." | tee -a /var/libre_install.log
        if ! ping -c1 8.8.8.8 >> /var/libre_install.log; then
                echo "`date +%s` You need internet to proceed. Exiting" | tee -a /var/libre_install.log
                exit 1
        fi

        echo "`date +%s` Checking DNS resolution ..." | tee -a /var/libre_install.log
        if ! getent hosts github.com >> /var/libre_install.log; then
                echo "`date +%s` You need DNS resolution to proceed... Exiting" | tee -a /var/libre_install.log
                exit 1
        fi

        echo "`date +%s` Showing the interface configuration ..." | tee -a /var/libre_install.log
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
}


# ----------------------------------------------
# configure_repositories
# ----------------------------------------------
configure_repositories()
{
        # Configuring main repositories before any installation
        cat << EOF >  /etc/apt/sources.list
deb http://ftp.debian.org/debian jessie main
deb http://ftp.debian.org/debian jessie-updates main
deb http://security.debian.org jessie/updates main
deb http://ftp.debian.org/debian jessie-backports main
deb-src http://ftp.debian.org/debian jessie main
deb-src http://ftp.debian.org/debian jessie-updates main
deb-src http://security.debian.org jessie/updates main
deb-src http://ftp.debian.org/debian jessie-backports main
EOF

        echo "`date +%s` Time sync ..." | tee -a /var/libre_install.log

        # Installing ntpdate package
        apt-get update >> /var/libre_install.log
        apt-get -y --force-yes install ntp ntpdate >> /var/libre_install.log

        # Time synchronization
        /etc/init.d/ntp stop >> /var/libre_install.log 2>> /var/libre_install.log
        if ntpdate -u ntp.ubuntu.com; then
            echo "`date +%s` Date and time have been set" | tee -a /var/libre_install.log
        elif ntpdate -u 0.ubuntu.pool.ntp.org; then
            echo "`date +%s` Date and time have been set" | tee -a /var/libre_install.log
        elif ntpdate -u 1.ubuntu.pool.ntp.org; then
            echo "`date +%s` Date and time have been set" | tee -a /var/libre_install.log
        elif ntpdate -u 2.ubuntu.pool.ntp.org; then
            echo "`date +%s` Date and time have been set" | tee -a /var/libre_install.log
        elif ntpdate -u 3.ubuntu.pool.ntp.org; then
            echo "`date +%s` Date and time have been set" | tee -a /var/libre_install.log
        elif [ $? -ne 0 ]; then
            echo "`date +%s` Error: unable to set time" | tee -a /var/libre_install.log
            exit 3
        fi
        /etc/init.d/ntp restart >> /var/libre_install.log 2>> /var/libre_install.log
        date | tee -a /var/libre_install.log

        # Configuring hostname and domain name
        echo "librerouter" > /etc/hostname
        echo "127.0.0.1 localhost.librenet librerouter localhost" > /etc/hosts
        sysctl kernel.hostname=librerouter

        echo "`date +%s` Configuring repositories ... " | tee -a /var/libre_install.log

        # echo "adding unauthenticated upgrade"
        apt-get  -y --force-yes --allow-unauthenticated upgrade

        echo "
Acquire::https::dl.dropboxusercontent.com::Verify-Peer \"false\";
Acquire::https::deb.nodesource.com::Verify-Peer \"false\";
        " > /etc/apt/apt.conf.d/apt.conf


        if [ $PLATFORM = "D8" ]; then
                # Avoid macchanger asking for information
                export DEBIAN_FRONTEND=noninteractive

                # Configuring Repositories for Debian 8
                #echo "deb http://ftp.es.debian.org/debian/ jessie main" > /etc/apt/sources.list
                #echo "deb http://ftp.es.debian.org/debian/ jessie-updates main" >> /etc/apt/sources.list
                #echo "deb http://security.debian.org/ jessie/updates main" >> /etc/apt/sources.list
                cat << EOF >  /etc/apt/sources.list
deb http://ftp.debian.org/debian jessie main
deb http://ftp.debian.org/debian jessie-updates main
deb http://security.debian.org jessie/updates main
deb http://ftp.debian.org/debian jessie-backports main
deb-src http://ftp.debian.org/debian jessie main
deb-src http://ftp.debian.org/debian jessie-updates main
deb-src http://security.debian.org jessie/updates main
deb-src http://ftp.debian.org/debian jessie-backports main
EOF

                # There is a need to install apt-transport-https
                # package before preparing third party repositories
                echo "`date +%s` Updating repositories ..." | tee -a /var/libre_install.log
                apt-get update 2>&1 > /var/apt-get-update-default.log
                echo "`date +%s` Installing apt-transport-https ..." | tee -a /var/libre_install.log
                apt-get install -y --force-yes apt-transport-https 2>&1 > /var/apt-get-install-aptth.log
                if [ $? -ne 0 ]; then
                        echo "`date +%s` Error: Unable to install apt-transport-https" | tee -a /var/libre_install.log
                        exit 3
                fi

#               # Prepare Sogo repo
#               apt-key adv --keyserver keys.gnupg.net --recv-key 0x810273C4
#               echo 'deb http://packages.inverse.ca/SOGo/nightly/3/debian/ jessie jessie' > /etc/apt/sources.list.d/sogo.list

#               # Prepare prosody repo
#               echo 'deb http://packages.prosody.im/debian wheezy main' > /etc/apt/sources.list.d/prosody.list
#               wget https://prosody.im/files/prosody-debian-packages.key -O- | apt-key add -

#               # Prepare tahoe repo
#               # echo 'deb https://dl.dropboxusercontent.com/u/18621288/debian wheezy main' > /etc/apt/sources.list.d/tahoei2p.list

#               # Prepare yacy repo
#               echo 'deb http://debian.yacy.net ./' > /etc/apt/sources.list.d/yacy.list
#               apt-key advanced --keyserver pgp.net.nz --recv-keys 03D886E7

#               # Prepare i2p repo
#               echo 'deb https://deb.i2p2.de/ stable main' > /etc/apt/sources.list.d/i2p.list
#               wget --no-check-certificate https://geti2p.net/_static/i2p-debian-repo.key.asc -O- | apt-key add -

#               # Prepare tor repo
#               echo 'deb http://deb.torproject.org/torproject.org jessie main'  > /etc/apt/sources.list.d/tor.list
#               gpg --keyserver pgp.net.nz --recv 886DDD89
#               gpg --export A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89 | apt-key add -

#               # Prepare Webmin repo
#               echo 'deb http://download.webmin.com/download/repository sarge contrib' > /etc/apt/sources.list.d/webmin.list
#               if [ -e jcameron-key.asc ]; then
#                       rm -r jcameron-key.asc
#               fi
#               wget http://www.webmin.com/jcameron-key.asc
#               apt-key add jcameron-key.asc

#               # Prepare kibaba repo
#               wget -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | apt-key add -
#               echo "deb https://packages.elastic.co/kibana/4.6/debian stable main" > /etc/apt/sources.list.d/kibana.list

#               # Prepare lohstash repo
#               wget -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | apt-key add -
#               echo "deb https://packages.elastic.co/logstash/2.4/debian stable main" > /etc/apt/sources.list.d/elastic.list


#               # Prepare backports repo (suricata, roundcube)
#               echo 'deb http://ftp.debian.org/debian jessie-backports main' > /etc/apt/sources.list.d/backports.list

#               # Prepare bro repo
#               wget http://download.opensuse.org/repositories/network:bro/Debian_8.0/Release.key -O- | apt-key add -
#               echo 'deb http://download.opensuse.org/repositories/network:/bro/Debian_8.0/ /' > /etc/apt/sources.list.d/bro.list

                # Prepare elastic repo
#               wget https://packages.elastic.co/GPG-KEY-elasticsearch -O- | apt-key add -
#               echo "deb http://packages.elastic.co/kibana/4.5/debian stable main" > /etc/apt/sources.list.d/kibana.list
#               echo "deb https://packages.elastic.co/logstash/2.3/debian stable main" > /etc/apt/sources.list.d/logstash.list
#               echo "deb https://packages.elastic.co/elasticsearch/2.x/debian stable main" > /etc/apt/sources.list.d/elastic.list

#               # Prepare passenger repo
#               apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 561F9B9CAC40B2F7
#               echo "deb https://oss-binaries.phusionpassenger.com/apt/passenger jessie main" > /etc/apt/sources.list.d/passenger.list

        else
                echo "ERROR: UNKNOWN PLATFORM"
                exit 4
        fi
}


# ----------------------------------------------
# install_packages
# ----------------------------------------------
install_packages()
{
        echo "`date +%s` Updating repositories packages ... " | tee -a /var/libre_install.log
        apt-get update 2>&1 > /var/apt-get-update.log
        echo "`date +%s` Installing packages ... " | tee -a /var/libre_install.log

if [ $PLATFORM = "D8" ]; then
        DEBIAN_FRONTEND=noninteractive

        # libs and tools
        echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes php5-common 2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes php5-fpm  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes php5-cli 2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes php5-json  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes php5-mysql  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes php5-curl  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes php5-intl  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes php5-mcrypt  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes php5-memcache  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes php-xml-parser  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes php-pear  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes phpmyadmin  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes php5  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes mailutils  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes apache2  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes libapache2-mod-php5  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes libapache2-modsecurity  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes libapache2-mod-fcgid  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes libapache2-mod-passenger  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes openjdk-7-jre-headless  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes php5-gd  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes php5-imap  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes smarty3  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes git  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes ntpdate  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes macchanger  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes bridge-utils  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes hostapd  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes librrd-dev  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes curl  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes macchanger  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes ntpdate  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes bc  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes sudo  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes lsb-release  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes dnsutils 2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes ca-certificates-java  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes openssh-server  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes ssh  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes wireless-tools  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes usbutils  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes unzip 2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes debian-keyring 2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes subversion 2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes build-essential 2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes libncurses5-dev 2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
#   apt-get install -y --force-yes i2p-keyring 2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes virtualenv 2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes pwgen 2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes gcc 2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes g++  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes make  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes automake 2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes killyourtv-keyring  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes libcurl4-gnutls-dev 2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes libicapapi-dev 2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes libssl-dev 2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes perl  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes screen  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes aptitude 2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes deb.torproject.org-keyring  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes u-boot-tools  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes php-zeta-console-tools 2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes gnupg  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes openssl  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes python-virtualenv  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes python-pip  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes python-lxml  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes git  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes libjpeg62-turbo  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes libjpeg62-turbo-dev  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes zlib1g-dev  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes python-dev 2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes libxml2-dev 2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes libxslt1-dev  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes python-jinja2  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes python-pgpdump  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes spambayes 2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes flex 2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes bison  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes libpcap-dev  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes libnet1-dev  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes libpcre3-dev  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes iptables-dev 2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes libnetfilter-queue-dev 2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes libdumbnet-dev autoconf rails 2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes roundcube-mysql 2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes roundcube-plugins 2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
#   apt-get install -y --force-yes ntop 2>&1 | tee -a /var/libre_install.log
    apt-get install -y --force-yes libndpi-bin 2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes argus-server  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes argus-client 2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes libnids-dev  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes flow-tools  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes libfixbuf3 2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes libgd-perl 2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes libgd-graph-perl 2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes rrdtool  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes librrd-dev  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes librrds-perl 2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes libsqlite3-dev  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes libtool  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes elasticsearch  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes conky  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes ruby  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes bundler 2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes pmacct 2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes tomcat7 2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes dpkg-dev  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes devscripts  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes javahelper  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes openjdk-7-jdk  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes ant 2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes librrds-perl 2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes apache2-prefork-dev  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes libmysqlclient-dev 2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes wkhtmltopdf 2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes libpcre3 2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes mysql-server 2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes mysql-client-5.5  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes iw  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes rfkill 2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes libfile-tail-perl  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes libfile-pid-perl  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes libwww-perl 2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes dialog 2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes wpasupplicant  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log


    # services
    apt-get install -y --force-yes roundcube 2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes dovecot-mysql 2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes dovecot-imapd 2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes postgrey 2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes amavis 2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes spamassassin 2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes php5-imap 2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes fail2ban 2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes libsystemd-dev  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log

fi
        if [ $? -ne 0 ]; then
                echo "`date +%s` Error: unable to install packages" | tee -a /var/libre_install.log
                exit 3
        fi

# Getting Friendica
echo "Getting Friendica ..." | tee -a /var/libre_install.log
if [ ! -e  /var/www/friendica ]; then
        cd /var/www
        git clone https://github.com/friendica/friendica.git
        if [ $? -ne 0 ]; then
                echo "`date +%s` Error: unable to download friendica" | tee -a /var/libre_install.log
                exit 3
        fi
        cd friendica
        git clone https://github.com/friendica/friendica-addons.git addon
        if [ $? -ne 0 ]; then
                echo "`date +%s` Error: unable to download friendica addons" | tee -a /var/libre_install.log
                exit 3
        fi

        chown -R www-data:www-data /var/www/friendica/view/smarty3
        chmod g+w /var/www/friendica/view/smarty3
        touch /var/www/friendica/.htconfig.php
        chown www-data:www-data /var/www/friendica/.htconfig.php
        chmod g+rwx /var/www/friendica/.htconfig.php
fi
}


# ----------------------------------------------
# Function to install modsecurity
# ----------------------------------------------
install_modsecurity()
{
        echo "`date +%s` Installing modsecurity OWASP Core Rule Set..." | tee -a /var/libre_install.log

        # Downloading the OWASP Core Rule Set
        cd /usr/src/
        rm -rf owasp-modsecurity-crs
        git clone https://github.com/SpiderLabs/owasp-modsecurity-crs.git
        if [ $? -ne 0 ]; then
                echo "`date +%s` Error: unable to download modsecurity rules. Exiting ..." | tee -a /var/libre_install.log
                exit 3
        fi

        cd $INSTALL_HOME
}


# ---------------------------------------------------------
# Function to install WAF-FLE (Modsecurity GUI)
# ---------------------------------------------------------
install_waffle()
{
        echo "`date +%s` Installing WAF-FLE ..." | tee -a /var/libre_install.log

        # installing dependencies
        apt-get install -y --force-yes php5-geoip php-apc


        rm -rf /usr/local/waf-fle
        mkdir -p /usr/local/waf-fle/


        if [ ! -e waf-fle ]; then
                echo "`date +%s` Downloading waf-fle ..." | tee -a /var/libre_install.log
                git clone https://github.com/klaubert/waf-fle/
                if [ $? -ne 0 ]; then
                        echo "`date +%s` Unable to download waf-fle. Exiting ..." | tee -a /var/libre_install.log
                        exit 3
                fi
        fi

        # Decompressing package
        cp -r waf-fle/ /usr/local/

        # Download MaxMind GeoIP Database

        mkdir /usr/share/GeoIP/
        cd /usr/share/GeoIP/
        rm -r /usr/share/GeoIP/*

        if [ ! -e GeoIP.dat.gz ]; then
                echo "`date +%s` Downloading GeoIP.dat ..." | tee -a /var/libre_install.log
                wget http://geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz
                if [ $? -ne 0 ]; then
                        echo "`date +%s` Unable to download GeoIP.dat. Exiting ..." | tee -a /var/libre_install.log
                        exit 3
                fi
        fi

        if [ ! -e GeoLiteCity.dat.gz ]; then
                echo "`date +%s` Downloading GeoLiteCity.dat ..." | tee -a /var/libre_install.log
                wget http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz
                if [ $? -ne 0 ]; then
                        echo "`date +%s` Unable to download GeoLiteCity.dat. Exiting ..." | tee -a /var/libre_install.log
                        exit 3
                fi
        fi

        if [ ! -e GeoIPASNum.dat.gz ]; then
                echo "`date +%s` Downloading GeoIPASNum.dat ..." | tee -a /var/libre_install.log
                wget http://geolite.maxmind.com/download/geoip/database/asnum/GeoIPASNum.dat.gz
                if [ $? -ne 0 ]; then
                        echo "`date +%s` Unable to download GeoIPASNum.dat. Exiting ..." | tee -a /var/libre_install.log
                        exit 3
                fi
        fi

        # Decompressing packages
        gzip -d GeoIP.dat.gz
        gzip -d GeoLiteCity.dat.gz
        gzip -d GeoIPASNum.dat.gz

        mv GeoLiteCity.dat GeoIPCity.dat
        # To make php GeoIP extension work with ASNum database
        cp GeoIPASNum.dat GeoIPISP.dat
}


# -----------------------------------------------
# Function to install ssl certificates
# -----------------------------------------------
install_certificates()
{
        echo "`date +%s` Installing certificates ..." | tee -a /var/libre_install.log

        GITLAB_TOKEN="nzkgoSpuepdiUuqnfboa"
BASE_DIR="root/Librekernell/raw/gh-pages/certs/"

echo "Downloading certificates ..." | tee -a /var/libre_install.log

mkdir -p /etc/ssl/apache/conference
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/conference/conference_librerouter_net.ca-bundle?private_token=$GITLAB_TOKEN > /etc/ssl/apache/conference/conference_librerouter_net.ca-bundle
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/conference/conference_librerouter_net.crt?private_token=$GITLAB_TOKEN > /etc/ssl/apache/conference/conference_librerouter_net.crt
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/conference/conference_librerouter_net.csr?private_token=$GITLAB_TOKEN > /etc/ssl/apache/conference/conference_librerouter_net.csr
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/conference/conference_librerouter_net.key?private_token=$GITLAB_TOKEN > /etc/ssl/apache/conference/conference_librerouter_net.key
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/conference/conference_librerouter_net.p7b?private_token=$GITLAB_TOKEN > /etc/ssl/apache/conference/conference_librerouter_net.p7b

mkdir -p /etc/ssl/apache/email
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/email/email_librerouter_net.ca-bundle?private_token=$GITLAB_TOKEN > /etc/ssl/apache/email/email_librerouter_net.ca-bundle
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/email/email_librerouter_net.crt?private_token=$GITLAB_TOKEN > /etc/ssl/apache/email/email_librerouter_net.crt
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/email/email_librerouter_net.csr?private_token=$GITLAB_TOKEN > /etc/ssl/apache/email/email_librerouter_net.csr
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/email/email_librerouter_net.key?private_token=$GITLAB_TOKEN > /etc/ssl/apache/email/email_librerouter_net.key
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/email/email_librerouter_net.p7b?private_token=$GITLAB_TOKEN > /etc/ssl/apache/email/email_librerouter_net.p7b

mkdir -p /etc/ssl/apache/gitlab
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/gitlab/gitlab_librerouter_net.ca-bundle?private_token=$GITLAB_TOKEN > /etc/ssl/apache/gitlab/gitlab_librerouter_net.ca-bundle
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/gitlab/gitlab_librerouter_net.crt?private_token=$GITLAB_TOKEN > /etc/ssl/apache/gitlab/gitlab_librerouter_net.crt
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/gitlab/gitlab_librerouter_net.csr?private_token=$GITLAB_TOKEN > /etc/ssl/apache/gitlab/gitlab_librerouter_net.csr
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/gitlab/gitlab_librerouter_net.key?private_token=$GITLAB_TOKEN > /etc/ssl/apache/gitlab/gitlab_librerouter_net.key

mkdir -p /etc/ssl/apache/glype
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/glype/glype_librerouter_net.ca-bundle?private_token=$GITLAB_TOKEN > /etc/ssl/apache/glype/glype_librerouter_net.ca-bundle
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/glype/glype_librerouter_net.crt?private_token=$GITLAB_TOKEN > /etc/ssl/apache/glype/glype_librerouter_net.crt
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/glype/glype_librerouter_net.csr?private_token=$GITLAB_TOKEN > /etc/ssl/apache/glype/glype_librerouter_net.csr
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/glype/glype_librerouter_net.key?private_token=$GITLAB_TOKEN > /etc/ssl/apache/glype/glype_librerouter_net.key

mkdir -p /etc/ssl/apache/ntop
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/ntop/ntop_librerouter_net.ca-bundle?private_token=$GITLAB_TOKEN > /etc/ssl/apache/ntop/ntop_librerouter_net.ca-bundle
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/ntop/ntop_librerouter_net.crt?private_token=$GITLAB_TOKEN > /etc/ssl/apache/ntop/ntop_librerouter_net.crt
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/ntop/ntop_librerouter_net.csr?private_token=$GITLAB_TOKEN > /etc/ssl/apache/ntop/ntop_librerouter_net.csr
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/ntop/ntop_librerouter_net.key?private_token=$GITLAB_TOKEN > /etc/ssl/apache/ntop/ntop_librerouter_net.key

mkdir -p /etc/ssl/apache/postfix
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/postfix/postfix_librerouter_net.ca-bundle?private_token=$GITLAB_TOKEN > /etc/ssl/apache/postfix/postfix_librerouter_net.ca-bundle
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/postfix/postfix_librerouter_net.crt?private_token=$GITLAB_TOKEN > /etc/ssl/apache/postfix/postfix_librerouter_net.crt
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/postfix/postfix_librerouter_net.csr?private_token=$GITLAB_TOKEN > /etc/ssl/apache/postfix/postfix_librerouter_net.csr
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/postfix/postfix_librerouter_net.key?private_token=$GITLAB_TOKEN > /etc/ssl/apache/postfix/postfix_librerouter_net.key

mkdir -p /etc/ssl/apache/redmine
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/redmine/redmine_librerouter_net.ca-bundle?private_token=$GITLAB_TOKEN > /etc/ssl/apache/redmine/redmine_librerouter_net.ca-bundle
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/redmine/redmine_librerouter_net.crt?private_token=$GITLAB_TOKEN > /etc/ssl/apache/redmine/redmine_librerouter_net.crt
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/redmine/redmine_librerouter_net.csr?private_token=$GITLAB_TOKEN > /etc/ssl/apache/redmine/redmine_librerouter_net.csr
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/redmine/redmine_librerouter_net.key?private_token=$GITLAB_TOKEN > /etc/ssl/apache/redmine/redmine_librerouter_net.key

mkdir -p /etc/ssl/apache/roundcube
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/roundcube/roundcube_librerouter_net.ca-bundle?private_token=$GITLAB_TOKEN > /etc/ssl/apache/roundcube/roundcube_librerouter_net.ca-bundle
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/roundcube/roundcube_librerouter_net.crt?private_token=$GITLAB_TOKEN > /etc/ssl/apache/roundcube/roundcube_librerouter_net.crt
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/roundcube/roundcube_librerouter_net.csr?private_token=$GITLAB_TOKEN > /etc/ssl/apache/roundcube/roundcube_librerouter_net.csr
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/roundcube/roundcube_librerouter_net.key?private_token=$GITLAB_TOKEN > /etc/ssl/apache/roundcube/roundcube_librerouter_net.key

mkdir -p /etc/ssl/apache/search
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/search/search_librerouter_net.ca-bundle?private_token=$GITLAB_TOKEN > /etc/ssl/apache/search/search_librerouter_net.ca-bundle
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/search/search_librerouter_net.crt?private_token=$GITLAB_TOKEN > /etc/ssl/apache/search/search_librerouter_net.crt
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/search/search_librerouter_net.csr?private_token=$GITLAB_TOKEN > /etc/ssl/apache/search/search_librerouter_net.csr
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/search/search_librerouter_net.key?private_token=$GITLAB_TOKEN > /etc/ssl/apache/search/search_librerouter_net.key
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/search/search_librerouter_net.p7b?private_token=$GITLAB_TOKEN > /etc/ssl/apache/search/search_librerouter_net.p7b

mkdir -p /etc/ssl/apache/social
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/social/social_librerouter_net.ca-bundle?private_token=$GITLAB_TOKEN > /etc/ssl/apache/social/social_librerouter_net.ca-bundle
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/social/social_librerouter_net.crt?private_token=$GITLAB_TOKEN > /etc/ssl/apache/social/social_librerouter_net.crt
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/social/social_librerouter_net.csr?private_token=$GITLAB_TOKEN > /etc/ssl/apache/social/social_librerouter_net.csr
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/social/social_librerouter_net.key?private_token=$GITLAB_TOKEN > /etc/ssl/apache/social/social_librerouter_net.key
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/social/social_librerouter_net.p7b?private_token=$GITLAB_TOKEN > /etc/ssl/apache/social/social_librerouter_net.p7b

mkdir -p /etc/ssl/apache/sogo
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/sogo/sogo_librerouter_net.ca-bundle?private_token=$GITLAB_TOKEN > /etc/ssl/apache/sogo/sogo_librerouter_net.ca-bundle
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/sogo/sogo_librerouter_net.crt?private_token=$GITLAB_TOKEN > /etc/ssl/apache/sogo/sogo_librerouter_net.crt
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/sogo/sogo_librerouter_net.csr?private_token=$GITLAB_TOKEN > /etc/ssl/apache/sogo/sogo_librerouter_net.csr
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/sogo/sogo_librerouter_net.key?private_token=$GITLAB_TOKEN > /etc/ssl/apache/sogo/sogo_librerouter_net.key

mkdir -p /etc/ssl/apache/squidguard
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/squidguard/squidguard_librerouter_net.ca-bundle?private_token=$GITLAB_TOKEN > /etc/ssl/apache/squidguard/squidguard_librerouter_net.ca-bundle
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/squidguard/squidguard_librerouter_net.crt?private_token=$GITLAB_TOKEN > /etc/ssl/apache/squidguard/squidguard_librerouter_net.crt
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/squidguard/squidguard_librerouter_net.csr?private_token=$GITLAB_TOKEN > /etc/ssl/apache/squidguard/squidguard_librerouter_net.csr
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/squidguard/squidguard_librerouter_net.key?private_token=$GITLAB_TOKEN > /etc/ssl/apache/squidguard/squidguard_librerouter_net.key

mkdir -p /etc/ssl/apache/storage
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/storage/storage_librerouter_net.ca-bundle?private_token=$GITLAB_TOKEN > /etc/ssl/apache/storage/storage_librerouter_net.ca-bundle
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/storage/storage_librerouter_net.crt?private_token=$GITLAB_TOKEN > /etc/ssl/apache/storage/storage_librerouter_net.crt
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/storage/storage_librerouter_net.csr?private_token=$GITLAB_TOKEN > /etc/ssl/apache/storage/storage_librerouter_net.csr
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/storage/storage_librerouter_net.key?private_token=$GITLAB_TOKEN > /etc/ssl/apache/storage/storage_librerouter_net.key
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/storage/storage_librerouter_net.p7b?private_token=$GITLAB_TOKEN > /etc/ssl/apache/storage/storage_librerouter_net.p7b

mkdir -p /etc/ssl/apache/trac
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/trac/trac_librerouter_net.ca-bundle?private_token=$GITLAB_TOKEN > /etc/ssl/apache/trac/trac_librerouter_net.ca-bundle
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/trac/trac_librerouter_net.crt?private_token=$GITLAB_TOKEN > /etc/ssl/apache/trac/trac_librerouter_net.crt
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/trac/trac_librerouter_net.csr?private_token=$GITLAB_TOKEN > /etc/ssl/apache/trac/trac_librerouter_net.csr
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/trac/trac_librerouter_net.key?private_token=$GITLAB_TOKEN > /etc/ssl/apache/trac/trac_librerouter_net.key

mkdir -p /etc/ssl/apache/waffle
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/waffle/waffle_librerouter_net.ca-bundle?private_token=$GITLAB_TOKEN > /etc/ssl/apache/waffle/waffle_librerouter_net.ca-bundle
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/waffle/waffle_librerouter_net.crt?private_token=$GITLAB_TOKEN > /etc/ssl/apache/waffle/waffle_librerouter_net.crt
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/waffle/waffle_librerouter_net.csr?private_token=$GITLAB_TOKEN > /etc/ssl/apache/waffle/waffle_librerouter_net.csr
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/waffle/waffle_librerouter_net.key?private_token=$GITLAB_TOKEN > /etc/ssl/apache/waffle/waffle_librerouter_net.key

mkdir -p /etc/ssl/apache/webconsole
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/webconsole/webconsole_librerouter_net.ca-bundle?private_token=$GITLAB_TOKEN > /etc/ssl/apache/webconsole/webconsole_librerouter_net.ca-bundle
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/webconsole/webconsole_librerouter_net.crt?private_token=$GITLAB_TOKEN > /etc/ssl/apache/webconsole/webconsole_librerouter_net.crt
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/webconsole/webconsole_librerouter_net.csr?private_token=$GITLAB_TOKEN > /etc/ssl/apache/webconsole/webconsole_librerouter_net.csr
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/webconsole/webconsole_librerouter_net.key?private_token=$GITLAB_TOKEN > /etc/ssl/apache/webconsole/webconsole_librerouter_net.key

mkdir -p /etc/ssl/apache/webmin
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/webmin/webmin_librerouter_net.ca-bundle?private_token=$GITLAB_TOKEN > /etc/ssl/apache/webmin/webmin_librerouter_net.ca-bundle
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/webmin/webmin_librerouter_net.crt?private_token=$GITLAB_TOKEN > /etc/ssl/apache/webmin/webmin_librerouter_net.crt
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/webmin/webmin_librerouter_net.csr?private_token=$GITLAB_TOKEN > /etc/ssl/apache/webmin/webmin_librerouter_net.csr
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/webmin/webmin_librerouter_net.key?private_token=$GITLAB_TOKEN > /etc/ssl/apache/webmin/webmin_librerouter_net.key

mkdir -p /etc/ssl/apache/snorby
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/snorby/snorby_librerouter_net.ca-bundle?private_token=$GITLAB_TOKEN > /etc/ssl/apache/snorby/snorby_librerouter_net.ca-bundle
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/snorby/snorby_librerouter_net.crt?private_token=$GITLAB_TOKEN > /etc/ssl/apache/snorby/snorby_librerouter_net.crt
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/snorby/snorby_librerouter_net.csr?private_token=$GITLAB_TOKEN > /etc/ssl/apache/snorby/snorby_librerouter_net.csr
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/snorby/snorby_librerouter_net.key?private_token=$GITLAB_TOKEN > /etc/ssl/apache/snorby/snorby_librerouter_net.key

mkdir -p /etc/ssl/apache/gui
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/gui/gui_librerouter_net.ca-bundle?private_token=$GITLAB_TOKEN > /etc/ssl/apache/gui/gui_librerouter_net.ca-bundle
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/gui/gui_librerouter_net.crt?private_token=$GITLAB_TOKEN > /etc/ssl/apache/gui/gui_librerouter_net.crt
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/gui/gui_librerouter_net.csr?private_token=$GITLAB_TOKEN > /etc/ssl/apache/gui/gui_librerouter_net.csr
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/gui/gui_librerouter_net.key?private_token=$GITLAB_TOKEN > /etc/ssl/apache/gui/gui_librerouter_net.key

mkdir -p /etc/ssl/apache/dns
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/dns/dns_librerouter_net.ca-bundle?private_token=$GITLAB_TOKEN > /etc/ssl/apache/dns/dns_librerouter_net.ca-bundle
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/dns/dns_librerouter_net.crt?private_token=$GITLAB_TOKEN > /etc/ssl/apache/dns/dns_librerouter_net.crt
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/dns/dns_librerouter_net.csr?private_token=$GITLAB_TOKEN > /etc/ssl/apache/dns/dns_librerouter_net.csr
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/dns/dns_librerouter_net.key?private_token=$GITLAB_TOKEN > /etc/ssl/apache/dns/dns_librerouter_net.key

if [ $? -ne 0 ]; then
        echo "`date +%s` Error: unable to download certificates. Exiting ..." | tee -a /var/libre_install.log
        exit 3
fi


}


# -----------------------------------------------
# Function to install ModSecurity Rules
# -----------------------------------------------
install_modsecrules()
{
        echo "`date +%s` Installing ModSecurity Rules ..." | tee -a /var/libre_install.log
        GITLAB_TOKEN="nzkgoSpuepdiUuqnfboa"
BASE_DIR="root/Librekernell/raw/gh-pages/ModSecurityRules"
mkdir /usr/src/ModSecurityRules
mkdir -p /usr/src/ModSecurityRules/Comodo

# wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/conference/conference_librerouter_net.ca-bundle?private_token=$GITLAB_TOKEN > /etc/ssl/apache/conference/conference_librerouter_net.ca-bundle

wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Comodo/00_Init_Initialization.conf?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Comodo/00_Init_Initialization.conf
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Comodo/01_Global_Generic.conf?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Comodo/01_Global_Generic.conf
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Comodo/02_Global_Agents.conf?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Comodo/02_Global_Agents.conf
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Comodo/03_Global_Domains.conf?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Comodo/03_Global_Domains.conf
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Comodo/04_Global_Exceptions.conf?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Comodo/04_Global_Exceptions.conf
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Comodo/05_Global_Incoming.conf?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Comodo/05_Global_Incoming.conf
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Comodo/06_Global_Backdoor.conf?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Comodo/06_Global_Backdoor.conf
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Comodo/07_XSS_XSS.conf?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Comodo/07_XSS_XSS.conf
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Comodo/08_Global_Other.conf?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Comodo/08_Global_Other.conf
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Comodo/09_Bruteforce_Bruteforce.conf?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Comodo/09_Bruteforce_Bruteforce.conf
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Comodo/10_HTTP_HTTP.conf?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Comodo/10_HTTP_HTTP.conf
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Comodo/11_HTTP_HTTPDoS.conf?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Comodo/11_HTTP_HTTPDoS.conf
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Comodo/12_HTTP_Protocol.conf?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Comodo/12_HTTP_Protocol.conf
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Comodo/13_HTTP_Request.conf?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Comodo/13_HTTP_Request.conf
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Comodo/14_Outgoing_FilterGen.conf?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Comodo/14_Outgoing_FilterGen.conf
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Comodo/15_Outgoing_FilterASP.conf?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Comodo/15_Outgoing_FilterASP.conf
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Comodo/16_Outgoing_FilterPHP.conf?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Comodo/16_Outgoing_FilterPHP.conf
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Comodo/17_Outgoing_FilterIIS.conf?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Comodo/17_Outgoing_FilterIIS.conf
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Comodo/18_Outgoing_FilterSQL.conf?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Comodo/18_Outgoing_FilterSQL.conf
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Comodo/19_Outgoing_FilterOther.conf?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Comodo/19_Outgoing_FilterOther.conf
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Comodo/20_Outgoing_FilterInFrame.conf?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Comodo/20_Outgoing_FilterInFrame.conf
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Comodo/21_Outgoing_FiltersEnd.conf?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Comodo/21_Outgoing_FiltersEnd.conf
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Comodo/22_PHP_PHPGen.conf?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Comodo/22_PHP_PHPGen.conf
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Comodo/23_SQL_SQLi.conf?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Comodo/23_SQL_SQLi.conf
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Comodo/24_ROR_RORGen.conf?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Comodo/24_ROR_RORGen.conf
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Comodo/25_Init_AppsInitialization.conf?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Comodo/25_Init_AppsInitialization.conf
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Comodo/26_Apps_Joomla.conf?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Comodo/26_Apps_Joomla.conf
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Comodo/27_Apps_JComponent.conf?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Comodo/27_Apps_JComponent.conf
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Comodo/28_Apps_WordPress.conf?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Comodo/28_Apps_WordPress.conf
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Comodo/29_Apps_WPPlugin.conf?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Comodo/29_Apps_WPPlugin.conf
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Comodo/30_Apps_WHMCS.conf?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Comodo/30_Apps_WHMCS.conf
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Comodo/31_Apps_Drupal.conf?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Comodo/31_Apps_Drupal.conf
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Comodo/32_Apps_OtherApps.conf?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Comodo/32_Apps_OtherApps.conf
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Comodo/LICENSE.txt?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Comodo/LICENSE.txt
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Comodo/bl_agents?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Comodo/bl_agents
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Comodo/bl_domains?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Comodo/bl_domains
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Comodo/bl_input?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Comodo/bl_input
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Comodo/bl_os_files?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Comodo/bl_os_files
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Comodo/bl_output?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Comodo/bl_output
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Comodo/bl_php_functions?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Comodo/bl_php_functions
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Comodo/bl_scanners?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Comodo/bl_scanners
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Comodo/bl_scanners_headers?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Comodo/bl_scanners_headers
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Comodo/bl_scanners_urls?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Comodo/bl_scanners_urls
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Comodo/categories.conf?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Comodocategories.conf
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Comodo/cwatch_managed_domains?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Comodo/cwatch_managed_domains
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Comodo/cwatch_protected_domains?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Comodo/cwatch_protected_domains
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Comodo/exclude.yml?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Comodo/exclude.yml
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Comodo/rules.conf.main?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Comodo/rules.conf.main
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Comodo/rules.dat?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Comodo/rules.dat
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Comodo/scheme.yml?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Comodo/scheme.yml
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Comodo/userdata_bl_IPs?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Comodo/userdata_bl_IPs
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Comodo/userdata_bl_URLs?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Comodo/userdata_bl_URLs
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Comodo/userdata_bl_agents?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Comodo/userdata_bl_agents
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Comodo/userdata_bl_cookies?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Comodo/userdata_bl_cookies
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Comodo/userdata_bl_domains?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Comodo/userdata_bl_domains
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Comodo/userdata_bl_extensions?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Comodo/userdata_bl_extensions
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Comodo/userdata_bl_headers?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Comodo/userdata_bl_headers
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Comodo/userdata_bl_referers?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Comodo/userdata_bl_referers
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Comodo/userdata_login_pages?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Comodo/userdata_login_pages
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Comodo/userdata_wl_IPs?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Comodo/userdata_wl_IPs
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Comodo/userdata_wl_URLs?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Comodo/userdata_wl_URLs
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Comodo/userdata_wl_agents?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Comodo/userdata_wl_agents
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Comodo/userdata_wl_content_type?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Comodo/userdata_wl_content_type
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Comodo/userdata_wl_domains?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Comodo/userdata_wl_domains
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Comodo/userdata_wl_extensions?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Comodo/userdata_wl_extensions
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Comodo/userdata_wl_methods?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Comodo/userdata_wl_methods
mkdir -p /usr/src/ModSecurityRules/Owasp
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Owasp/crs-setup.conf?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Owasp/crs-setup.conf

mkdir -p /usr/src/ModSecurityRules/Owasp/rules

wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Owasp/rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf.example?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Owasp/rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf.example
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Owasp/rules/REQUEST-901-INITIALIZATION.conf?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Owasp/rules/REQUEST-901-INITIALIZATION.conf
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Owasp/rules/REQUEST-903.9001-DRUPAL-EXCLUSION-RULES.conf?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Owasp/rules/REQUEST-903.9001-DRUPAL-EXCLUSION-RULES
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Owasp/rules/REQUEST-903.9002-WORDPRESS-EXCLUSION-RULES.conf?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Owasp/rules/REQUEST-903.9002-WORDPRESS-EXCLUSION-RULES.conf
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Owasp/rules/REQUEST-905-COMMON-EXCEPTIONS.conf?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Owasp/rules/REQUEST-905-COMMON-EXCEPTIONS.conf
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Owasp/rules/REQUEST-910-IP-REPUTATION.conf?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Owasp/rules/REQUEST-910-IP-REPUTATION.conf
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Owasp/rules/REQUEST-911-METHOD-ENFORCEMENT.conf?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Owasp/rules/REQUEST-911-METHOD-ENFORCEMENT.conf
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Owasp/rules/REQUEST-912-DOS-PROTECTION.conf?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Owasp/rules/REQUEST-912-DOS-PROTECTION.conf
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Owasp/rules/REQUEST-913-SCANNER-DETECTION.conf?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Owasp/rules/REQUEST-913-SCANNER-DETECTION.conf
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Owasp/rules/REQUEST-920-PROTOCOL-ENFORCEMENT.conf?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Owasp/rules/REQUEST-920-PROTOCOL-ENFORCEMENT.conf
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Owasp/rules/REQUEST-921-PROTOCOL-ATTACK.conf?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Owasp/rules/REQUEST-921-PROTOCOL-ATTACK.conf
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Owasp/rules/REQUEST-930-APPLICATION-ATTACK-LFI.conf?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Owasp/rules/REQUEST-930-APPLICATION-ATTACK-LFI.conf
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Owasp/rules/REQUEST-931-APPLICATION-ATTACK-RFI.conf?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Owasp/rules/REQUEST-931-APPLICATION-ATTACK-RFI.conf
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Owasp/rules/REQUEST-932-APPLICATION-ATTACK-RCE.conf?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Owasp/rules/REQUEST-932-APPLICATION-ATTACK-RCE.conf
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Owasp/rules/REQUEST-933-APPLICATION-ATTACK-PHP.conf?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Owasp/rules/REQUEST-933-APPLICATION-ATTACK-PHP.conf
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Owasp/rules/REQUEST-941-APPLICATION-ATTACK-XSS.conf?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Owasp/rules/REQUEST-941-APPLICATION-ATTACK-XSS.conf
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Owasp/rules/REQUEST-942-APPLICATION-ATTACK-SQLI.conf?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Owasp/rules/REQUEST-942-APPLICATION-ATTACK-SQLI.conf
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Owasp/rules/REQUEST-943-APPLICATION-ATTACK-SESSION-FIXATION.conf?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Owasp/rules/REQUEST-943-APPLICATION-ATTACK-SESSION-FIXATION.conf

wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Owasp/rules/REQUEST-949-BLOCKING-EVALUATION.conf?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Owasp/rules/REQUEST-949-BLOCKING-EVALUATION.conf
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Owasp/rules/RESPONSE-950-DATA-LEAKAGES?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Owasp/rules/RESPONSE-950-DATA-LEAKAGES
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Owasp/rules/RESPONSE-951-DATA-LEAKAGES-SQL.conf?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Owasp/rules/RESPONSE-951-DATA-LEAKAGES
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Owasp/rules/RESPONSE-952-DATA-LEAKAGES-JAVA.conf?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Owasp/rules/RESPONSE-952-DATA-LEAKAGES-JAVA.conf
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Owasp/rules/RESPONSE-953-DATA-LEAKAGES-PHP.conf?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Owasp/rules/RESPONSE-953-DATA-LEAKAGES-PHP.conf
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Owasp/rules/RESPONSE-954-DATA-LEAKAGES-IIS.conf?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Owasp/rules/RESPONSE-954-DATA-LEAKAGES-IIS.conf
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Owasp/rules/RESPONSE-959-BLOCKING-EVALUATION.conf?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Owasp/rules/RESPONSE-959-BLOCKING-EVALUATION.conf
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Owasp/rules/RESPONSE-980-CORRELATION.conf?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Owasp/rules/RESPONSE-980-CORRELATION.conf
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Owasp/rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf.example?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Owasp/rules/?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Owasp/rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf.example
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Owasp/rules/crawlers-user-agents.data?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Owasp/rules/crawlers-user-agents.data
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Owasp/rules/iis-errors.data?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Owasp/rules/iis-errors.data
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Owasp/rules/java-code-leakages.data?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Owasp/rules/java-code-leakages.data
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Owasp/rules/java-errors.data?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Owasp/rules/java-errors.data
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Owasp/rules/lfi-os-files.data?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Owasp/rules/lfi-os-files.data
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Owasp/rules/modsecurity_crs_11_waffle.conf?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Owasp/rules/modsecurity_crs_11_waffle.conf
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Owasp/rules/php-config-directives.data?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Owasp/rules/php-config-directives.data
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Owasp/rules/php-errors.data?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Owasp/rules/php-errors.data
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Owasp/rules/php-function-names-933150.data?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Owasp/rules/php-function-names-933150.data
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Owasp/rules/php-function-names-933151.data?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Owasp/rules/php-function-names-933151.data
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Owasp/rules/php-variables.data?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Owasp/rules/php-variables.data
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Owasp/rules/restricted-files.data?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Owasp/rules/restricted-files.data
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Owasp/rules/scanners-headers.data?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Owasp/rules/scanners-headers.data
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Owasp/rules/scanners-urls.data?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Owasp/rules/scanners-urls.data
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Owasp/rules/scanners-user-agents.data?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Owasp/rules/scanners-user-agents.data
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Owasp/rules/scripting-user-agents.data?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Owasp/rules/scripting-user-agents.data
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Owasp/rules/sql-errors.data?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Owasp/rules/sql-errors.data
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Owasp/rules/sql-function-names.data?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Owasp/rules/sql-function-names.data
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Owasp/rules/unix-shell.data?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Owasp/rules/unix-shell.data
wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/Owasp/rules/windows-powershell-commands.data?private_token=$GITLAB_TOKEN > /usr/src/ModSecurityRules/Owasp/rules/windows-powershell-commands.data


                if [ $? -ne 0 ]; then
                        echo "`date +%s` Error: unable to download ModSecurity Rules. Exiting ..." | tee -a /var/libre_install.log
                        exit 3
                fi


}


# ----------------------------------------------
# Function to install mailpile package
# ----------------------------------------------
install_mailpile()
{
        echo "`date +%s` Installing Mailpile ..." | tee -a /var/libre_install.log
        apt-get install -y --force-yes libffi-dev
        if [ ! -e /opt/Mailpile ]; then
                echo "`date +%s` Downloading mailpile ..." | tee -a /var/libre_install.log
                git clone --recursive \
                https://github.com/mailpile/Mailpile.git /opt/Mailpile
                if [ $? -ne 0 ]; then
                        echo "`date +%s` Error: unable to download Mailpile. Exiting ..." | tee -a /var/libre_install.log
                        exit 3
                fi

        fi
        virtualenv -p /usr/bin/python2.7 --system-site-packages /opt/Mailpile/mailpile-env
        source /opt/Mailpile/mailpile-env/bin/activate

        pip install packaging
        pip install appdirs
        pip install --upgrade six

        pip install -r /opt/Mailpile/requirements.txt
        if [ $? -ne 0 ]; then
                echo "`date +%s` Error: unable to install Mailpile. Exiting ..." | tee -a /var/libre_install.log
                exit 3
        fi
}


# -----------------------------------------------
# Function to install nextcloud
# -----------------------------------------------
install_nextcloud()
{
        echo "`date +%s` Installing nextcloud ..." | tee -a /var/libre_install.log

        # Deleting previous packages
        rm -rf /var/www/nextcloud

        if [ ! -e  nextcloud-12.0.0.zip ]; then
                echo "`date +%s` Downloading nextcloud ..." | tee -a /var/libre_install.log
                wget https://download.nextcloud.com/server/releases/nextcloud-12.0.0.zip
                # wget https://download.owncloud.org/community/owncloud-9.1.1.tar.bz2
                if [ $? -ne 0 ]; then
                        echo "`date +%s` Error: Unable to download nextcloud. Exiting ..." | tee -a /var/libre_install.log
                        exit 3
                fi

        fi

        unzip nextcloud-12.0.0.zip
        mv nextcloud /var/www/nextcloud

        # Installing ojsxc xmpp client
        if [ ! -e ojsxc-3.0.1.zip ]; then
                echo "`date +%s` Downlouding ojsxc ..." | tee -a /var/libre_install.log
                wget https://github.com/owncloud/jsxc.chat/releases/download/v3.0.1/ojsxc-3.0.1.zip
                if [ $? -ne 0 ]; then
                        echo "`date +%s` Error: Unable to download ojsxc. Exiting ..." | tee -a /var/libre_install.log
                        exit 3
                fi
        fi

        unzip ojsxc-3.0.1.zip
        mv ojsxc /var/www/nextcloud/apps

        chown -R www-data /var/www/nextcloud
}


# ---------------------------------------------------------
# Function to install glype proxy server
# ---------------------------------------------------------
install_glype()
{
        echo "`date +%s` Installing glype ..." | tee -a /var/libre_install.log

        # Downloading glype-1.4.15
        if [ ! -e glype-1.4.15.zip ]; then
            wget http://netix.dl.sourceforge.net/project/free-proxy-server/glype-1.4.15%20%281%29.zip
            if [ $? -ne 0 ]; then
                echo "`date +%s` Error: unable to download glype" | tee -a /var/libre_install.log
                exit 3
            fi
            mv glype-1.4.15\ \(1\).zip glype-1.4.15.zip
        fi

        unzip glype-1.4.15.zip -d glype-1.4.15
        rm -rf /var/www/glype

        # Creating glype home
        mkdir /var/www/glype
        cp -R glype-1.4.15/* /var/www/glype
        chmod 777 /var/www/glype/includes/settings.php
        chmod 777 /var/www/glype/tmp/

        # Cleanup
        rm -rf glype-1.4.15
}


# ---------------------------------------------------------
# Function to install trac server
# ---------------------------------------------------------
install_trac()
{
        if [ "$ARCH" == "x86_64" ]; then
                echo "Installing trac ..." | tee -a /var/libre_install.log
                apt-get -y --force-yes install trac
                if [ $? -ne 0 ]; then
                        echo "`date +%s` Error: unable to install trac. Exiting ..." | tee -a /var/libre_install.log
                        exit 3
                fi
        else
                echo "`date +%s` Skipping trac installation. x86_64 Needed / Detected: $ARCH" | tee -a /var/libre_install.log
        fi
}


# ---------------------------------------------------------
# Function to install redmine server
# ---------------------------------------------------------
install_redmine()
{
if [ "$ARCH" == "x86_64" ]; then
        echo "`date +%s` Installing redmine ..." | tee -a /var/libre_install.log
        apt-get -y --force-yes install \
        mysql-server mysql-client libmysqlclient-dev \
        gcc build-essential zlib1g zlib1g-dev zlibc \
        ruby-zip libssl-dev libyaml-dev libcurl4-openssl-dev \
        ruby ruby2.1 gem libapr1-dev libxslt1-dev checkinstall \
        libxml2-dev ruby-dev vim libmagickwand-dev imagemagick
        if [ $? -ne 0 ]; then
                echo "`date +%s` Error: unable to install redmine. Exiting ..." | tee -a /var/libre_install.log
                exit
        fi

        rm -rf /opt/redmine
        mkdir /opt/redmine
        chown -R www-data /opt/redmine
        cd /opt/redmine

        if [ ! -e redmine-3.3.1 ]; then
                echo "`date +%s` Downloading redmine ..." | tee -a /var/libre_install.log
                wget http://www.redmine.org/releases/redmine-3.3.1.tar.gz
                if [ $? -ne 0 ]; then
                        echo "`date +%s` Error: unable to download redmine. Exiting ..." | tee -a /var/libre_install.log
                        exit
                fi
                tar xzf redmine-3.3.1.tar.gz
        fi
        cd redmine-3.3.1

        # Install bundler
        gem install bundler
        if [ $? -ne 0 ]; then
                echo "`date +%s` Error: unable to install bundler. Exiting ..." | tee -a /var/libre_install.log
                exit 3
        fi

        echo "gem 'thin'" > Gemfile.local
        bundle install --without development test
        thin install

        # Generate secret token
        bundle exec rake generate_secret_token

        # Prepare DB and install all tables:
        #RAILS_ENV=production bundle exec rake db:migrate
        #RAILS_ENV=production bundle exec rake redmine:load_default_data
else
        echo "`date +%s` Skipping redmine installation. x86_64 Needed / Detected: $ARCH" | tee -a /var/libre_install.log
fi
}


# -----------------------------------------------
# Function to install postfixadmin
# -----------------------------------------------
install_postfix()
{
        echo "`date +%s` Installing postfix ..." | tee -a /var/libre_install.log
        DEBIAN_FRONTEND=noninteractive apt-get -y --force-yes install postfix postfixadmin postfix-mysql
        if [ $? -ne 0 ]; then
                echo "`date +%s` Error: Unable to install postfix. Exiting" | tee -a /var/libre_install.log
                exit 3
        fi

        # Download postfixadmin database
        if [ ! -e postfixadmin.txt ]; then
                echo "`date +%s` Downloading postfixadmin database ..." | tee -a /var/libre_install.log
                wget https://www.nesono.com/sites/default/files/postfixadmin.txt
                if [ $? -ne 0 ]; then
                        echo "`date +%s` Unable to download postfixadmin database. Exiting ..." | tee -a /var/libre_install.log
                        exit 3
                fi
        fi
}


# -----------------------------------------------
# Function to install webconsole
# -----------------------------------------------
install_webconsole()
{
echo "`date +%s` Installing webconsole ..."  | tee -a /var/libre_install.log

if [ ! -e /var/www/webconsole/webconsole.php ]; then
    cd /var/www/
    wget https://github.com/nickola/web-console/releases/download/v0.9.7/webconsole-0.9.7.zip

    if [ $? -ne 0 ]; then
        echo "`date +%s` Unable to download webconsole. Exiting ..." | tee -a /var/libre_install.log
        exit 3
    fi

    # Unzip webconsole package
    unzip webconsole-0.9.7.zip

    # Cleanup
    rm -rf webconsole-0.9.7.zip

    cd $INSTALL_HOME
fi
}


# -----------------------------------------------
# Function to install Librerouter GUI
# -----------------------------------------------
install_gui()
{
    echo "`date +%s` Installing librerouter gui ..."  | tee -a /var/libre_install.log

    # Creating GUI root directory for apache web server
    mkdir -p /var/www/gui
    mkdir -p /var/www/gui/img


    echo "`date +%s` Downloading GUI source" | tee -a /var/libre_install.log
    GITLAB_TOKEN="nzkgoSpuepdiUuqnfboa"
    BASE_DIR="root/Librekernell/raw/gh-pages/GUI"

    wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/filters.txt?private_token=$GITLAB_TOKEN > /var/www/gui/filters.txt
    wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/index.cgi?private_token=$GITLAB_TOKEN > /var/www/gui/index.cgi
    wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/resources.cgi?private_token=$GITLAB_TOKEN > /var/www/gui/resources.cgi
    wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/security.txt?private_token=$GITLAB_TOKEN > /var/www/gui/security.txt
    wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/services.txt?private_token=$GITLAB_TOKEN > /var/www/gui/services.txt
    wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/submit.cgi?private_token=$GITLAB_TOKEN > /var/www/gui/submit.cgi

    wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/img/diluvium.png?private_token=$GITLAB_TOKEN > /var/www/gui/img/diluvium.png
    wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/img/diluvium_logo.png?private_token=$GITLAB_TOKEN > /var/www/gui/img/diluvium_logo.png
    wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/img/running.png?private_token=$GITLAB_TOKEN > /var/www/gui/img/running.png
    wget --no-check-certificate -O - https://154.61.99.254:444/$BASE_DIR/img/stoped.png?private_token=$GITLAB_TOKEN > /var/www/gui/img/stoped.png

    if [ $? -ne 0 ]; then
        echo "`date +%s` Error: unable to download gui files. Exiting ..." | tee -a /var/libre_install.log
        exit 3
    fi

    # Seting permission
    chmod +x /var/www/gui/*.cgi
}


# ----------------------------------------------
# MAIN
# ----------------------------------------------
# This is the main function of this script.
# ----------------------------------------------

	check_root               # Checking user
	check_internet           # Check Internet access
	configure_repositories   # Prepare and update repositories
        install_packages         # Download and install packages
        install_modsecurity      # Install modsecurity package
        install_waffle           # Install modsecurity GUI WAF-FLE package
        install_certificates     # Install ssl certificates
        install_modsecrules      # Install Modsecurity rules
        install_mailpile         # Install Mailpile package
        install_nextcloud        # Install Owncloud package
        install_glype            # Install glype proxy
        install_trac             # Install trac package
        install_redmine          # Install redmine package
        install_postfix          # Install postfixadmin package
        install_webconsole       # Install webconsole package
        install_gui              # Install GUI interface files
