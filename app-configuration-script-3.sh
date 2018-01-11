#!/bin/bash
# ---------------------------------------------------------
#
# Configuration script for Librerouter Module 3
#
# Version: 1.0
# Author:  Librerouter Team
# ---------------------------------------------------------


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
10.0.0.235      dns.librerouter.net
10.0.0.236      gui.librerouter.net
10.0.0.237      webconsole.librerouter.net
10.0.0.238      waffle.librerouter.net
10.0.0.239      snorby.librerouter.net
10.0.0.240      glype.librerouter.net
10.0.0.241      sogo.librerouter.net
10.0.0.242      postfix.librerouter.net
10.0.0.243      roundcube.librerouter.net
10.0.0.244      ntop.librerouter.net
10.0.0.245      webmin.librerouter.net
10.0.0.246      squidguard.librerouter.net
10.0.0.247      gitlab.librerouter.net
10.0.0.248      trac.librerouter.net
10.0.0.249      redmine.librerouter.net
10.0.0.250      conference.librerouter.net
10.0.0.251      search.librerouter.net
10.0.0.252      social.librerouter.net
10.0.0.253      storage.librerouter.net
10.0.0.254      email.librerouter.net
EOF
}


# ---------------------------------------------------------
# This function configures internal and external interfaces
# ---------------------------------------------------------
configure_interfaces()
{
        echo "Configuring Interfaces ..." | tee -a /var/libre_config.log
        # Network interfaces configuration for
        # Physical/Virtual machine

        cat << EOF >  /etc/network/interfaces
        # interfaces(5) file used by ifup(8) and ifdown(8)
        auto lo
        iface lo inet loopback

        #Internal network interface
        auto $INT_INTERFACE
        #allow-hotplug $INT_INTERFACE
        iface $INT_INTERFACE inet static
        bridge_ports eth1 wlan1
            address 10.0.0.3
            netmask 255.255.255.0
            network 10.0.0.0
EOF

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

iptables -t nat -A PREROUTING -i $INT_INTERFACE -p tcp -d 10.0.0.2 --dport 8090 -j REDIRECT --to-ports 8090
iptables -t nat -A PREROUTING -i $INT_INTERFACE -p tcp -d 10.0.0.2 --dport 8081 -j REDIRECT --to-ports 8081
iptables -t nat -A PREROUTING -i $INT_INTERFACE -p tcp -d 10.0.0.2 --dport 20000 -j REDIRECT --to-ports 20000
iptables -t nat -A PREROUTING -i $INT_INTERFACE -p tcp -d 10.0.0.2 --dport 8443 -j REDIRECT --to-ports 8443
iptables -t nat -A PREROUTING -i $INT_INTERFACE -p tcp -d 10.0.0.2 --dport 22 -j REDIRECT --to-ports 22


# Block any other TCP-UDP connections
iptables -P INPUT DROP

# Time sync
ntpdate -s ntp.ubuntu.com

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


# ---------------------------------------------------------
# ************************ MAIN ***************************
# This is the main function on this script
# ---------------------------------------------------------

check_root                      # Checking user
get_interfaces                  # Get external and internal interfaces
configure_hosts                 # Configuring hostname and /etc/hosts
configure_interfaces            # Configuring external and internal interfaces
configure_reboot                # Configuring Reboot (Disabling Keyboard reboot
configure_iptables              # Configuring iptables rules
configure_ssh                   # Configuring ssh server
configure_yacy                  # Configuring yacy search engine
configure_easyrtc               # Configuring EasyRTC local service
configure_gitlab                # Configure gitlab servies (only for amd64)

