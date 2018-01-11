#!/bin/bash
# ---------------------------------------------------------
#
# Installation script for Librerouter Module 5 
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
# Function to install SquidClamav
# ----------------------------------------------
install_squidclamav()
{
        echo "`date +%s` Installing squidclamav ..." | tee -a /var/libre_install.log
        if [ ! -e /tmp/squidclamav-6.15.tar.gz ]; then
                echo "`date +%s` Downloading squidclamav ..." | tee -a /var/libre_install.log
                wget -P /tmp/ http://downloads.sourceforge.net/project/squidclamav/squidclamav/6.15/squidclamav-6.15.tar.gz
        fi

        if [ ! -e squidclamav-6.15 ]; then
                echo "`date +%s` Extracting squidclamav ..." | tee -a /var/libre_install.log
                tar zxvf /tmp/squidclamav-6.15.tar.gz
        fi

        echo "`date +%s` Building squidclamav ..." | tee -a /var/libre_install.log
        cd squidclamav-6.15
        ./configure --with-c-icap
        make && make install
        if [ $? -ne 0 ]; then
                echo "`date +%s` Error: unable to install squidclamav" | tee -a /var/libre_install.log
                exit 3
        fi
        cd ../

        # Creating configuration file
        ln -sf /etc/c-icap/squidclamav.conf /etc/squidclamav.conf
}


# ----------------------------------------------
# Function to install squidguard blacklists
# ----------------------------------------------
install_squidguard_bl()
{
        echo "`date +%s` Installing squidguard blacklists ..." | tee -a /var/libre_install.log

#       # squidguard-adblock
#       echo "Downloading squidguard-adblock ..."
#       git clone https://github.com/jamesmacwhite/squidguard-adblock.git
#       if [ $? -ne 0 ]; then
#               echo "Error: unable to download squidguard-adblock"
#               exit 3
#       fi
#       cd squidguard-adblock
#       mkdir -p /etc/squid/squidguard-adblock
#       cp get-easylist.sh /etc/squid/squidguard-adblock/
#       cp patterns.sed /etc/squid/squidguard-adblock/
#       cp urls.txt /etc/squid/squidguard-adblock/
#       chmod +x /etc/squid/squidguard-adblock/get-easylist.sh
#       cd ..

        # Getting MESD blacklists
        if [ ! -e blacklists.tgz ]; then
        wget http://squidguard.mesd.k12.or.us/blacklists.tgz
        fi
        # Getting ads blacklists
        if [ ! -e serverlist.php ]; then
        wget https://pgl.yoyo.org/as/serverlist.php
        fi
        # Getting urlblacklist blacklists
        if [ ! -e urlblacklist ]; then
        wget http://urlblacklist.com/cgi-bin/commercialdownload.pl?type=download\\&file=bigblacklist -O urlblacklist.tar.gz
        rm -rf blacklistdomains
        mkdir blacklistdomains
        cd blacklistdomains
        tar xvzf urlblacklist.tar.gz
        cd ../
        fi

        # Making squidGuard blacklists directory
        mkdir -p /usr/local/squidGuard/db
        # Extracting blacklists
        cp blacklists.tgz /usr/local/squidGuard/db
        tar xfv /usr/local/squidGuard/db/blacklists.tgz \
        -C /usr/local/squidGuard/db/
        # ads blacklists
        sed -n '57,2418p' < serverlist.php > /usr/local/squidGuard/db/blacklists/ads/domains
        # urlblacklist blacklists
        cat blacklistdomains/blacklists/ads/domains >> /usr/local/squidGuard/db/blacklists/ads/domains
        # Shalalist domains
        cat BL/adv/domains >> /usr/local/squidGuard/db/blacklists/ads/domains
        cat BL/adv/urls >> /usr/local/squidGuard/db/blacklists/ads/urls
        # Cleanup
        rm -rf /usr/local/squidGuard/db/blacklists.tar
#       rm -rf squidguard-adblock
}


# ---------------------------------------------------------
# Function to install squidguardmgr (Manager Gui)
# ---------------------------------------------------------
install_squidguardmgr()
{
        echo "`date +%s` Installing squidguardmgr ..." | tee -a /var/libre_install.log
        if [ ! -e squidguardmgr ]; then
                echo "`date +%s` Downloading squidguardmgr ..." | tee -a /var/libre_install.log
                git clone https://github.com/darold/squidguardmgr
                if [ $? -ne 0 ]; then
                        echo "`date +%s` Error: unable to download quidguardmgr" | tee -a /var/libre_install.log
                        exit 3
                fi
        fi

        echo "`date +%s` Building quidguardmgr ..." | tee -a /var/libre_install.log
        cd squidguardmgr
        perl Makefile.PL \
        CONFFILE=/etc/squidguard/squidGuard.conf \
        SQUIDUSR=root SQUIDGRP=root \
        SQUIDCLAMAV=off \
        QUIET=1

        make
        make install
        cd ../

        chmod a+rw /etc/squidguard/squidGuard.conf
}


# ----------------------------------------------
# Function to install ecapguardian
# ----------------------------------------------
install_ecapguardian()
{
        echo "`date +%s` Installing ecapguardian ..." | tee -a /var/libre_install.log

        if [ ! -e ecapguardian ]; then
        echo "Downloading ecapguardian ..."
        git clone https://github.com/androda/ecapguardian
                if [ $? -ne 0 ]; then
                        echo "`date +%s` Error: unable to download ecapguardian" | tee -a /var/libre_install.log
                        exit 3
                fi
        fi

        echo "`date +%s` Building ecapguardian ..." | tee -a /var/libre_install.log

        cd ecapguardian

        # Adding category
        sed -i  "s/N\/A/Pornography/g" src/HTMLTemplate.cpp

        # Adding subdir for automake
        sed -i '/AM_INIT_AUTOMAKE/c\AM_INIT_AUTOMAKE([subdir-objects])' configure.ac

        ./autogen.sh
        ./configure '--prefix=/usr' '--enable-clamd=yes' '--with-proxyuser=e2guardian' '--with-proxygroup=e2guardian' '--sysconfdir=/etc' '--localstatedir=/var' '--enable-icap=yes' '--enable-commandline=yes' '--enable-email=yes' '--enable-ntlm=yes' '--enable-trickledm=yes' '--mandir=${prefix}/share/man' '--infodir=${prefix}/share/info' 'CXXFLAGS=-g -O2 -fstack-protector --param=ssp-buffer-size=4 -Wformat -Werror=format-security' 'LDFLAGS=-Wl,-z,relro' 'CPPFLAGS=-D_FORTIFY_SOURCE=2' 'CFLAGS=-g -O2 -fstack-protector --param=ssp-buffer-size=4 -Wformat -Werror=format-security' '--enable-pcre=yes' '--enable-locallists=yes'
        make && make install
        if [ $? -ne 0 ]; then
                echo "`date +%s` Error: unable to install ecapguardian" | tee -a /var/libre_install.log
                exit 3
        fi
        cd ../

        # Cleanup
        # rm -rf ./ecapguardian
}


# ----------------------------------------------
# Function to install Suricata
# ----------------------------------------------
install_suricata()
{
        echo "`date +%s` Installing suricata ..." | tee -a /var/libre_install.log

        # Installing dependencies
        apt-get install -y --force-yes ethtool oinkmaster

        apt-get install -y -t jessie-backports ethtool suricata
        if [ $? -ne 0 ]; then
                echo "`date +%s` Error: unable to install suricata. Exiting ..." | tee -a /var/libre_install.log
                exit 3
        fi

        echo "`date +%s` Downloading rules ..." | tee -a /var/libre_install.log

        # Creating oinkmaster configuration
        echo "
skipfile local.rules
skipfile deleted.rules
skipfile snort.conf
        " > /etc/oinkmaster.conf
        echo "url = https://rules.emergingthreats.net/open/suricata-3.1/emerging.rules.tar.gz" \
        >> /etc/oinkmaster.conf
        oinkmaster -C /etc/oinkmaster.conf -o /etc/suricata/rules
        if [ $? -ne 0 ]; then
                echo "`date +%s` Error: unable to install suricata rules. Exiting ..." | tee -a /var/libre_install.log
                exit 3
        fi
}


# ----------------------------------------------
# Function to install Barnyard2
# ----------------------------------------------
install_barnyard()
{
        echo "`date +%s` Installing Barnyard ..." | tee -a /var/libre_install.log

        # Install dependencies
        apt-get install -y --force-yes dh-autoreconf libpcap-dev libmysqld-dev mysql-client autoconf

if [ ! -e /opt/daq-2.0.6 ]; then
        echo "`date +%s` Installing daq ..." | tee -a /var/libre_install.log
        cd /opt

        echo "`date +%s` Downloading daq ..." | tee -a /var/libre_install.log
        echo "52.216.227.35 s3.amazonaws.com" >> /etc/hosts
        wget --no-check-certificate https://www.snort.org/downloads/snort/daq-2.0.6.tar.gz
        sed '/s3.amazonaws.com/d' -i /etc/hosts
        if [ $? -ne 0 ]; then
                echo "`date +%s` Error: unable to download daq" | tee -a /var/libre_install.log
                exit 3
        fi

        # Decompress
        tar xvf daq-2.0.6.tar.gz

        # Build
        cd /opt/daq-2.0.6
        ./configure
        make
        make install
        if [ $? -ne 0 ]; then
                echo "`date +%s` Error: unable to install daq" | tee -a /var/libre_install.log
                exit 3
        fi
fi

if [ ! -e /opt/libdnet-1.11 ]; then
        echo "`date +%s` Installing libdnet ..." | tee -a /var/libre_install.log
        cd /opt

        echo "`date +%s` Downloading libdnet ..." | tee -a /var/libre_install.log
        wget https://netix.dl.sourceforge.net/project/libdnet/libdnet/libdnet-1.11/libdnet-1.11.tar.gz
        if [ $? -ne 0 ]; then
                echo "`date +%s` Error: unable to download libdnet" | tee -a /var/libre_install.log
                exit 3
        fi

        # Decompress
        tar xvf libdnet-1.11.tar.gz

        # Build
        cd /opt/libdnet-1.11
        ./configure
        make
        make install
        if [ $? -ne 0 ]; then
                echo "`date +%s` Error: unable to install libdnet" | tee -a /var/libre_install.log
                exit 3
        fi
fi

if [ ! -e /opt/barnyard2 ]; then
        echo "`date +%s` Installing barnyard ..." | tee -a /var/libre_install.log
        cd /opt

        echo "`date +%s` Downloading Barnyard ..." | tee -a /var/libre_install.log
        git clone https://github.com/firnsy/barnyard2.git
        if [ $? -ne 0 ]; then
                echo "`date +%s` Error: unable to download Barnyard" | tee -a /var/libre_install.log
                exit 3
        fi

        # Build
        cd barnyard2
        echo "`date +%s` Building Barnyard ..." | tee -a /var/libre_install.log
        ./autogen.sh
        ./configure --with-mysql --with-mysql-libraries=/usr/lib/x86_64-linux-gnu/
        make
        make install
        if [ $? -ne 0 ]; then
                echo "`date +%s` Error: unable to install Barnyard" | tee -a /var/libre_install.log
                exit 3
        fi
fi

cd $INSTALL_HOME
}


# ----------------------------------------------
# Function to install Snorby
# ----------------------------------------------
install_snorby()
{
        echo "`date +%s` Installing Snorby ..." | tee -a /var/libre_install.log

        # Installing dependencies
        apt-get install -y --force-yes default-jre libreadline-gplv2-dev libmysql++-dev libxslt-dev postgresql-server-dev-9.4

        # Prevent the install of documentation when gems are installed
        echo "gem: --no-rdoc --no-ri" > ~/.gemrc
        sh -c "echo gem: --no-rdoc --no-ri > /etc/gemrc"

        # Install bundler and rails
        gem install bundler rails wkhtmltopdf
        gem install rake --version=0.9.2

if [ ! -e /opt/snorby ]; then
        echo "`date +%s` Downloading Snorby ..." | tee -a /var/libre_install.log
        cd /opt
        git clone https://github.com/Snorby/snorby.git
        if [ $? -ne 0 ]; then
                echo "`date +%s` Error: unable to download Snorby" | tee -a /var/libre_install.log
                exit 3
        fi
        cd /opt/snorby
        echo "`date +%s` Installing snorby ..." | tee -a /var/libre_install.log
        bundle update do_mysql
        bundle update dm-mysql-adapter
        bundle install
        if [ $? -ne 0 ]; then
                echo "`date +%s` Error: unable to install snorby" | tee -a /var/libre_install.log
                exit 3
        fi
fi

cd $INSTALL_HOME
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
        install_squidclamav      # Install SquidClamav package
        install_squidguard_bl    # Install Squidguard blacklists
        install_squidguardmgr    # Install Squidguardmgr (Manager Gui)
        install_ecapguardian     # Inatall ecapguardian package
        install_suricata         # Install Suricata package
        install_barnyard         # Install Barnyard package
        install_snorby           # Install Snorby package

