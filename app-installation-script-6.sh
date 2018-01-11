#!/bin/bash
# ---------------------------------------------------------
#
# Installation script for Librerouter Module 6 
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

    # libs and tools
    apt-get install -y --force-yes git  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes ntpdate  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes sudo  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes openssh-server  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes unzip 2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes subversion 2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes build-essential 2>&1 | tee -a /var/libre_install.log
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
    apt-get install -y --force-yes iptables-dev 2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    
    # Services
    apt-get install -y --force-yes c-icap 2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes clamav 2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes clamav-daemon  2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes squidguard 2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log

    # services
    apt-get install -y --force-yes privoxy
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes c-icap 2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log
    apt-get install -y --force-yes tor 2>&1 | tee -a /var/libre_install.log
    echo "`date +%s`" |  tee -a /var/libre_install.log

        if [ $? -ne 0 ]; then
                echo "`date +%s` Error: unable to install packages" | tee -a /var/libre_install.log
                exit 3
        fi
}


# -----------------------------------------------
# Function to install libecap
# -----------------------------------------------
install_libecap()
{
        echo "`date +%s` Installing libecap ..." | tee -a /var/libre_install.log

        if [ ! -e libecap-1.0.0 ]; then
        echo "`date +%s` Downloading libecap ..." | tee -a /var/libre_install.log
        wget http://www.measurement-factory.com/tmp/ecap/libecap-1.0.0.tar.gz
                if [ $? -ne 0 ]; then
                        echo "`date +%s` Error: unable to download libecap" | tee -a /var/libre_install.log
                        exit 3
                fi
                tar xzf libecap-1.0.0.tar.gz
        fi

        echo "`date +%s` Building libecap ..." | tee -a /var/libre_install.log

        cd libecap-1.0.0/

        ./configure
        make &&  make install

        if [ $? -ne 0 ]; then
                echo "`date +%s` Error: unable to install libecap" | tee -a /var/libre_install.log
                exit 3
        fi
        cd ../

        # Cleanup
        rm -rf libecap-1.0.0.tar.gz
}


# -----------------------------------------------
# Function to install fg-ecap
# -----------------------------------------------
install_fg-ecap()
{
        echo "`date +%s` Installing fg-ecap ..." | tee -a /var/libre_install.log

        if [ ! -e fg_ecap ]; then
        echo "`date +%s` Downloading fg-ecap ..." | tee -a /var/libre_install.log
        git clone https://github.com/androda/fg_ecap $INSTALL_HOME/fg_ecap
                if [ $? -ne 0 ]; then
                        echo "`date +%s` Error: unable to download fg-ecap. Exitingi ..." | tee -a /var/libre_install.log
                        exit 3
                fi
        fi

        echo "`date +%s` Building fg-ecap ..." | tee -a /var/libre_install.log

        cd fg_ecap

        chmod +x autogen.sh
        ./autogen.sh
        ./configure
        make && make install
        if [ $? -ne 0 ]; then
                echo "`date +%s` Error: unable to install fg-ecap" | tee -a /var/libre_install.log
                exit 3
        fi
        cd ../
}


# -----------------------------------------------
# Function to install squid
# -----------------------------------------------
install_squid()
{
        echo "`date +%s` Installing squid dependences ..." | tee -a /var/libre_install.log
        aptitude -y build-dep squid

        echo "`date +%s` Installing squid ..." | tee -a /var/libre_install.log
        if [ ! -e /tmp/squid-3.5.21.tar.gz ]; then
                echo "`date +%s` Downloading squid ..." | tee -a /var/libre_install.log
                wget -P /tmp/ http://www.squid-cache.org/Versions/v3/3.5/squid-3.5.21.tar.gz
        fi

        if [ ! -e squid-3.5.21 ]; then
                echo "`date +%s` Extracting squid ..." | tee -a /var/libre_install.log
                tar zxvf /tmp/squid-3.5.21.tar.gz
        fi

        echo "`date +%s` Building squid ..." | tee -a /var/libre_install.log
        cd squid-3.5.21
        ./configure --prefix=/usr --localstatedir=/var \
                --libexecdir=/lib/squid --datadir=/usr/share/squid \
                --sysconfdir=/etc/squid --with-logdir=/var/log/squid \
                --with-pidfile=/var/run/squid.pid --enable-icap-client \
                --enable-linux-netfilter --enable-ssl-crtd --with-openssl \
                --enable-ltdl-convenience --enable-ssl \
                --enable-ecap PKG_CONFIG_PATH=/usr/local/lib/pkgconfig
        make && make install
        if [ $? -ne 0 ]; then
                echo "`date +%s` Error: unable to install squid" | tee -a /var/libre_install.log
                exit 3
        fi
        cd ../

        # Getting squid startup script
        if [ ! -e /etc/squid/squid3.rc ]; then
                wget -P /etc/squid/ https://raw.githubusercontent.com/grosskur/squid3-deb/master/debian/squid3.rc
        fi

        # squid adservers
        curl -sS -L --compressed \
        "http://pgl.yoyo.org/adservers/serverlist.php?mimetype=plaintext" \
                > /etc/squid/squid.adservers

        # squid adzapper
        wget http://adzapper.sourceforge.net/scripts/squid_redirect
        chmod +x ./squid_redirect
        mv squid_redirect /usr/bin/

        # Adding library path
        echo "include /usr/local/lib" >> /etc/ld.so.conf
        ldconfig
}


# ----------------------------------------------
# Function to install i2pd
# ----------------------------------------------
install_i2pd()
{
        echo "`date +%s` Installing i2pd ..." | tee -a /var/libre_install.log
        apt-get install -y --force-yes libboost-date-time-dev
        apt-get install -y --force-yes libboost-filesystem-dev
        apt-get install -y --force-yes libboost-program-options-dev
        apt-get install -y --force-yes libboost-system-dev
        apt-get install -y --force-yes libssl-dev
        apt-get install -y --force-yes zlib1g-dev
        apt-get install -y --force-yes libminiupnpc-dev
        apt-get install -y --force-yes fakeroot
        apt-get install -y --force-yes devscripts

        if [ ! -e i2pd ]; then
                echo "`date +%s` Downloading i2pd ..." | tee -a /var/libre_install.log
                git clone https://github.com/PurpleI2P/i2pd.git
                if [ $? -ne 0 ]; then
                        echo "`date +%s` Error: unable to download i2p. Exiting ..." | tee -a /var/libre_install.log
                        exit 3
                fi
        fi

        echo "`date +%s` Building i2p ..." | tee -a /var/libre_install.log
        cd i2pd
        debuild --no-tgz-check -b

        # Installing deb package
        dpkg -i ../i2pd_2.15.0-1_amd64.deb

#        if [ $? -ne 0 ]; then
#                echo "`date +%s` Error: unable to install i2p. Exiting ..." | tee -a /var/libre_install.log
#                exit 3
#        fi
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
        install_libecap          # Install libecap package
        install_fg-ecap          # Install fg-ecap package
        install_squid            # Install squid package
        install_i2pd             # Install i2pd proxy
