#!/bin/bash
# ---------------------------------------------------------
#
# Installation script for Librerouter Module 3 
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

               # Prepare Sogo repo
               apt-key adv --keyserver keys.gnupg.net --recv-key 0x810273C4
               echo 'deb http://packages.inverse.ca/SOGo/nightly/3/debian/ jessie jessie' > /etc/apt/sources.list.d/sogo.list

#               # Prepare prosody repo
#               echo 'deb http://packages.prosody.im/debian wheezy main' > /etc/apt/sources.list.d/prosody.list
#               wget https://prosody.im/files/prosody-debian-packages.key -O- | apt-key add -

#               # Prepare tahoe repo
#               # echo 'deb https://dl.dropboxusercontent.com/u/18621288/debian wheezy main' > /etc/apt/sources.list.d/tahoei2p.list

                # Prepare yacy repo
                echo 'deb http://debian.yacy.net ./' > /etc/apt/sources.list.d/yacy.list
                apt-key advanced --keyserver pgp.net.nz --recv-keys 03D886E7

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
    apt-get install -y --force-yes yacy 2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes sogo 2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log

fi
        if [ $? -ne 0 ]; then
                echo "`date +%s` Error: unable to install packages" | tee -a /var/libre_install.log
                exit 3
        fi


# ----------------------------------------------
# Function to install EasyRTC package
# ----------------------------------------------
install_easyrtc()
{
        echo "`date +%s` Installing EasyRTC package ..." | tee -a /var/libre_install.log

        # Creating home folder for EasyRTC
        if [ -e /opt/easyrtc ]; then
                rm -r /opt/easyrtc
        fi

        # Installing Node.js. Includes npm, then npm have been rmeoved from top apt-get
        echo "`date +%s` Install Nodejs/npm from sources" | tee -a /var/libre_install.log
        wget -O - https://nodejs.org/dist/v7.7.4/node-v7.7.4.tar.gz > node-v7.7.4.tar.gz
        tar xzf node-v7.7.4.tar.gz
        cd node-v7.7.4
        ./configure
        make && make install

        # Getting EasyRTC
        if [ ! -e easyrtc ]; then
                echo "`date +%s` Downloading EasyRTC ..." | tee -a /var/libre_install.log
                git clone --recursive \
                https://github.com/priologic/easyrtc
                if [ $? -ne 0 ]; then
                  echo "`date +%s` Error: Unable to download EasyRTC. Exiting ..." | tee -a /var/libre_install.log
                  exit 3
                fi
        fi

        # Moving server_example to /opt
        cp -r easyrtc /opt/

        # Downloading the required dependencies
        cd /opt/easyrtc
        npm install
        cd /opt/easyrtc/server_example/
        npm install
        if [ $? -ne 0 ]; then
                echo "`date +%s` Error: unable to install EasyRTC. Exiting" | tee -a /var/libre_install.log
                exit 3
        fi
        cd $INSTALL_HOME
}


# ---------------------------------------------------------
# Function to install gitlab package
# ---------------------------------------------------------
install_gitlab()
{
# Gitlab can only be installed on x86_64 (64 bit) architecture
if [ "$ARCH" == "x86_64" ]; then

        echo "`date +%s` Installing gitlab ..." | tee -a /var/libre_install.log

        # Check if gitlab is installed or not
        which gitlab-ctl >> /var/libre_install.log
        if [ $? -ne 0 ]; then
                # Install the necessary dependencies
                apt-get install -y --force-yes curl openssh-server ca-certificates postfix

#               if [ ! -e gitlab-ce_8.12.7-ce.0_amd64.deb ]; then
#               echo "Downloading Gitlab ..." | tee -a /var/libre_install.log
#               wget --no-check-certificat -O gitlab-ce_8.12.7-ce.0_amd64.deb \
#               https://packages.gitlab.com/gitlab/gitlab-ce/packages/debian/wheezy/gitlab-ce_8.12.7-ce.0_amd64.deb/download
#
#                       if [ $? -ne 0 ]; then
#                               echo "Error: unable to download Gitlab. Exiting ..." | tee -a /var/libre_install.log
#                               exit 3
#                       fi
#               fi
#
#               # Install gitlab
#               dpkg -i gitlab-ce_8.12.7-ce.0_amd64.deb
#               if [ $? -ne 0 ]; then
#                       echo "Error: unable to install Gitlab. Exiting ..." | tee -a /var/libre_install.log
#                       exit 3
#               fi

                # Installing from packages for dependencies
                curl -LO https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh
                bash script.deb.sh
                apt-get install -y --force-yes gitlab-ce
        fi
else
        echo "`date +%s` Skipping gitlab installation. x86_64 Needed / Detected: $ARCH" | tee -a /var/libre_install.log
fi
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
        install_easyrtc          # Install EasyRTC package
        install_gitlab           # Install gitlab packae        
