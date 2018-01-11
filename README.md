![diluvium](/uploads/4554e205b52b94c648bc555aa4c225a4/diluvium.png)

# Setting up the lab in physical:

Suported devices (any x86 or amd64)
You need to add a usb to ethernet adaptor or a second ethernet nic and 2 atheros (non firmaware required) wireless network interfaces. :

- 100% open source open Hardware Solidrun Clearfog.
- Gole1
- Qotom p104
- Pipo x10 and modified.
- Teclast Tbook 16 Power 
- Teclast xx98 plus 2 http://www.teclast.com/en/zt/X98PlusII/
- Chwi Hi10 or Chwi hi12
- Onda V919 Air CH

# Setting up the lab in Virtual:

Virtual Xen,ESXi,VirtualBox,qemu, or other vitrual lab:

- Internet Router<-----eth0----Debian64 latest version----eth1---Virtual Lan vswitch<---ethernet---Windows10
- Internet DHCP server--eth0---Debian64 latest version-----eth1--(debian dhcpserver)--------Win10 (dhcp client)

First of all you should install latest Debian 64bit version in a virtual machine (why Virtual? you can recover fresh install in seconds doing restoration of snapshot):

- 4GB RAM, 2 core procesors, 2NICs (network interfaces)

Recomended:
- 8GB RAM 8 Core processor.

Second PC emulating the client would be a non privacy friendly OS like a Win 10:
- VM requirements in microsoft
- Office 2016
- All possible browsers.dropbox client, seamonkey,firefox,chrome,edge,iexplorer,opera,chromiun.

Hardware resources:

- NIC1 will be NAT/bridged to your Internet dhcp server router.
- NIC2 will be a attached  via virtual switch or vlan to the other VM Windows10. (NIC 2 can be cable or WLAN Wireless and creates the secure LAN environment)

From debian to win 10 will be a private LAN in bridge mode. (would require promiscous because arp request from client to server)



![deded](images/Readme-Images/diagram.png)

Resume of steps, please be aware that debian should be simplest or non packages should be selected.

- In Virtualbox in debian like: https://jtreminio.com/2012/07/setting-up-a-debian-vm-step-by-step/
- Or any physical machine like https://www.debian.org/doc/manuals/debian-handbook/sect.installation-steps.en.html
- In the Debian please do a Snapshot in the Virtual machine just after being install.


Important note before testing : 

- Do NOT try to install the scripts via a ssh session. The scripts FAIL if you do that, due to problems with ethernet connection.
- Install the scripts via direct console access.

Go shell command console in debian and execute as root:


wget --no-check-certificate -O - https://154.61.99.254:444/root/Librekernell/raw/gh-pages/setup.sh?private_token=nzkgoSpuepdiUuqnfboa > setup.sh
./setup.sh



(Choose the wget o curl command that you prefer)
- wget -O - http://bit.ly/2gbKstn | bash


or

- wget --no-check-certificate https://raw.githubusercontent.com/Librerouter/Librekernel/gh-pages/setup.sh  
- chmod 777 setup.sh
- ./setup.sh

or

- apt-get install curl
- curl -L http://bit.ly/2gbKstn | bash


log files are in /var

- apt-get-install-aptth.log
- apt-get-update.log
- apt-get-install_1.log
- apt-get-install_2.log
- apt-get-update-default.log
- libre_install.log
- libre_config.log

### Lab done!

Try to navigate normally from the windows 10.
Report us problems, issues and recomentaditions plus request for features.
Investigate and play while we continue developing it.
New version of the instalaltion-configuration scripts,ISOs and OVA virtual machine export will be upcoming.


## What the setup.sh app-installation-script.sh , app-configuration-script.sh , service.sh and wizard.sh do?

The setup.sh app-installation-script.sh , app-configuration-script.sh , service.sh will be esclusevilly for mounters or assemblers person who mount proffesionall or assemble profesional our products not for the end user. 

setup.sh app-installation-script.sh , app-configuration-script.sh , service.sh requires of plug of physical internet ethernet cable connection.

The end user will be using a USB with auto-installable un-attended ISO image.

Wizard.sh is for the end user and will be maturing and its the first thing the ISO image will be launching.

### 2 future version of the ISO:

- Online: For more profesionals. All is downloaded and compiled.

- Offline Live debian: For non profesional and guided installation.


## Installation workflow:

a) Call setup.sh.

Setup download other scripts and prepare environment. Also reports errors in installacion via centralized repository.(in way to make descentralized).

a.1) Prepare environment
a.2) Replace kernel with libre kernel.
a.3) change sources to not allow non free.

c) App-installation-scrip.sh

App-installation script install all necesary packages. Via different ways: apts,compiling,preparing.
c.1) Tools for filtering
c.2) Server services
c.3) Drivers for open source Wlan devices.

![initial-install-workflow](images/Readme-Images/workflow1.png)

d) App-configuration-scrip.sh

App-configuration-script is the real CocaCola maker and in the future will be a encrypted blob, the result will remain be 100% opensource but the way to prepare will be secret. A hacker can duplicate and copy the whole rootfs and distribute it freely. 

e) wizard.sh

Wizard is the initial graphical user interface intendt that we created and will be replaced by a real GUI running in X limited browser.

f) services.sh

It shows up the addresses of your services from clearnet and darknets plus some important data and users.

g) Own development and integration of the opensource.

This already happened and will be increase as investors coming. The only inverstor is a single guy who invested 250k with 300 buyers from Crowdfunding that already losed their faith and patient. (invested 70k netto)


## Networking in Librerouter:

There are two bridges with two interfaces each in the machine like two bridges (only 2 separated zone NICs):
	
1. External area red bridge acting as WAN (2 nics): cable or wireless interface as DHCP client of your internet router.
2. Internal area gren bridge acting as LAN (2 nics): cable or wireless interface as an AP for being DHCP server for your new secure LAN.

## Four possible PHySICAL scenarios:

 - WAN is WiFi, LAN is WiFi
 - WAN is WiFi, LAN is Cabled Ethernet
 - WAN is Cabled Ethernet, LAN is WiFi
 - WAN is Cabled Ethernet, LAN is Cabled Ethernet

## Router bridge mode

![38](images/Readme-Images/router-bridge-mode.png)


Where the trafic is filtered by dns , by ip via iptables, by protocol, application layer signature and reputationally. 

![untitled](images/Readme-Images/cube.png)

![bridmodeworkflow](images/Readme-Images/workflow2.png)


# How Librerouter will threat the network traffic as a Privacy Firewall in router mode (most common).

![blocking_diagram_1](images/Readme-Images/blocking-policy.png)

 - a) Clean network web browsing traffic (IoT, cookies tracks, scripts tracks, malware, exploits, attackes, non privacy friendly corporations web servers)
 - b) Blocking not privacy friendly protocols and inspecting inside ssl tunnels.
 - c) Monitoring for abnormal behaviours.
 - d) Offering decentralized alternatives of the such called cloud services. 
 - e) Will clean files in storage erasing metadata Sanitization (optional to classified and personal information) 
 - f) Will protect the access to your webs publically in TOR-I2P and clearnet.(normal internet).
 - g) Will selfhost search engine,email,storage,conference,collaborative,git,project managing,socialnetwork, TOR shop.


# Architecture

Still pending to add suricata and modsecurity last changes.

![arch_new](images/Readme-Images/architecture.png)


# Engines especifications and configuration dependencies:

Add here owncloud with excel file.

## OSI STACK FROM DOWN TO UP:

![modsecuritylogo](images/Readme-Images/osi-stack1.png)

![modsecuritylogo](images/Readme-Images/osi-stack2.png)

## ARP protections

## Layer 3 IP Firewall Iptables configuration.

![protocols policy](images/Readme-Images/policy-default.png)

## Layer 4  Iptables NDPI configuration.



## DNS:

- NXFilter is the DNS SERVER, which has unbound as upstream DNS and goes to dns hsts bypass engine. 
- If it is not resolved then using cached then we use DNSCRYPT to ask D.I.A.N.A and OpenNIC.
- If it can not resolved, then we need to ask through TOR aleatory.
- Further integration will include Bitname,others like DjDNS (this last need maintenance is not workinghttps://github.com/DJDNS/djdns)).

![dnsipdate](images/Readme-Images/dns.png)
 
  * Search engines  - will be resolved to ip address 10.0.0.251 (Yacy) by unbound. and hsts downgraded and dns hardredirected.
  * Social network  - will be resolved to ip address 10.0.0.252 (friendics) by unbound. and hsts downgraded and dns hardredirected.
  * Online Storage  - Will be resolved to ip address 10.0.0.253 (Owncloud) by unbound. and hsts downgraded and dns hardredirected.
  * Webmails        - Will be resolved to ip address 10.0.0.254 (MailPile) by unbound. and hsts downgraded and dns hardredirected.
  
![redirection](images/Readme-Images/web-mails.png)

### Darknets Domains:
 
  * .local - will be resolved to local ip address (10.0.0.0/24 network) by unbound.
  * .i2p   - will be resolved to ip address 10.191.0.1 by unbound.
  * .onion - unbound will forward this zone to Tor DNS running on 10.0.0.1:9053
  
 -Freenet domains:> not yet implemented
- http://ftp.mirrorservice.org/sites/ftp.wiretapped.net/pub/security/cryptography/apps/freenet/fcptools/linux/gateway.html
- Bit domains> blockchain bitcoin> not yet implemented 
- https://en.wikipedia.org/wiki/Namecoin  https://bit.namecoin.info/
- Zeronet> not yet implemented
- Openbazaar> not yet implemented
![dnsipdated](images/Readme-Images/unbound-filter.png)
 

## Can the user in the future workaround the redirection in router mode:

Yes in the future via GUI should be possible to reconfigure this cage enabling services as plugins.



## Suricata Intrusion Prevention System Ruleset versus use cases configuration.

When user is using HTTPS connection to a darknet domain, this traffic it's considered dangerus and insecure. (the goverment try to explodes the browser for deanonymization) On darknet onion and i2p domains, squid will open the SSL tunnel and inspect for possible exploits, virus and attacks to the user.
If this connection it's to a HTTPS regular/banking domain, this SSL tunnel will be not open Bumped/inspected. Will be routed directly to the clearnet internet (ex: https://yourbank.com)

When the user is using HTTP, because is considered insecure itself this clear traffic is going to go through TOR to add anonymization but after a threatment from the local engines to add privacy on it.. The user can also decide in the future about which things he dont want to use TOr for HTTP.
To provide full internet security, we want IDS/IPS to inspect all kind of communications in our network: tor, i2p and direct.
But we also want to inspect all secure connections. To do so, we use squid proxy with ssl-bump feature to perform mitm.
All decrypted traffic goes to icap server, where it's being scanned by clam antivirus.

To accomplish our goal, we are going to make Suricata listen on two interfaces:
 -  On LAN Suricata is going to detect potentially bad traffic (incoming and outgoing), block attackers/compromised hosts, tor exit nodes, etc.
Suricata will inspect packets using default sets of rules: 
  Botnet Command and Control Server Rules (BotCC),
  ciarmy.com Top Attackers List,
  Known CompromisedHost List,
  Spamhaus.org DROP List,
  Dshield Top Attackers List,
  Tor exit Nodes List,
  Protocol events List.
 -  On localhost Suricata is supposed to scan icap port for bad content: browser/activex exploits, malware, attacks, etc.
Modified emerging signatures for browsers will be implemented for this purpose.

![untitled](images/Readme-Images/suricata.png)

**Suricata will prevent the following sets of attacks:**

a) Web Browsers
  - ActiveX Remote Code Execution
  - Microsoft IE ActiveX vulnerabilities
  - Microsoft Video ActiveX vulnerabilities
  - Snapshot Viewer for Microsoft Access ActiveX vulnerabilities
  - http backdoors (get/post)
  - DNS Poisoning
  - Suspicious/compromises hosts
  - ClickFraud URLs
  - Tor exit nodes
  - Chats vulnerabilities (Google Talk/Facebook)
  - Gaming sites vulnerabilities (Alien Arena/Battle.net/Steam)
  - Suspicious add-ins and add-ons downloading/execution
  - Javascript backdoors
  - trojans injections
  - Microsoft Internet Explorer vulnerabilities
  - Firefox vulnerabilities
  - Firefox plug-ins vulnerabilities
  - Google Chrome vulnerabilities
  - Malicious Chrome extencions
  - Android Browser vulnerabilities
  - PDF vulnerabilities
  - Stealth code execution
  - Adobe Shockwave Flash vulnerabilities
  - Adobe Flash Player vulnerabilities
  - Browser plug-in commands injections
  - Microsoft Office format vulnerabilities
  - Adobe PDF Reader vulnerabilities
  - spyware
  - adware
  - Web scans
  - SQL Injection Points
  - Suspicious self-signed sertificates
  - Dynamic DNS requests to suspicious domains
  - Metasploits
  - Suspicious Java requests
  - Suspicious python requests
  - Phishing pages
  - java.runtime execution
  - Malicious files downloading

b) Librerouter (router services)
  - mysql attacks
  - Apache/nginx Brute Force Attacks
  - GPL attack responses
  - php remote code injections
  - Apache vulnerabilities
  - Apache OGNL exploits
  - Oracle Java vulnerabilities
  - PHP exploits
  - node.js exploits
  - ssh attacks

c) User devices
  - GPL attack responses
  - Metasploit Meterpreter
  - Remote Windows command execution
  - Remote Linux command execution
  - IMAP attacks
  - pop3 attacks
  - smtp attacks
  - Messengers vulnerabilities (ICQ/MSN/Jabber/TeamSpeak)
  - Gaming software vulnerabilities (Steam/PunkBuster/Minecraft/UT/TrackMania/WoW)
  - Microsoft Windows vulnerabilities
  - OSX vulnerabilities
  - FreeBSD vulnerabilities
  - Redhat 7 vulnerabilities
  - Apple QuickTime vulnerabilities
  - RealPlayer/VLC exploits
  - Adobe Acrobat vulnerabilities
  - Worms, spambots
  - Web specific apps vulnerabilities
  - voip exploits
  - Android trojans
  - SymbOS trojans
  - Mobile Spyware
  - iOS malware
  - NetBios exploits
  - Oracle Java vulnerabilities
  - RPC vulnerabilities
  - telnet vulnerabilities
  - MS-SQL exploits
  - dll injections
  - Microsoft Office vulnerabilities
  - rsh exploits


**Loopback issue:**

Suricata >=3.1 is unable to listen on loopback in afp mode. When run with -i lo option, it dies with this messages:

\<Error\> - [ERRCODE: SC_ERR_INVALID_VALUE(130)] - Frame size bigger than block size

\<Error\> - [ERRCODE: SC_ERR_AFP_CREATE(190)] - Couldn't init AF_PACKET socket, fatal error

Same configuration works fine with Suricata v3.0.0.

**Possible solutions:**

- Use pcap mode on lo and af-packet on eth0. May not be possible, because since 3.1 Suricata use af-packet mode by default
- Reduce the MTU size



![espacioblanco](https://cloud.githubusercontent.com/assets/17382786/14488687/b41768ba-0169-11e6-96cd-80377e21231d.png)

In Librerouter we are using Suricata as a service which listens to loopback interface. 
Suricata package have been installed from debian reposirty. Package name: suricata

In suricata we have enabled following free open-source rules.
- url = http://rules.emergingthreats.net/open/suricata/emerging.rules.tar.gz

Suricataâ€™s log size limit to 100mb

As a GUI interface for suricata we use Snorby.
snorby.librerouter.net â€“ 10.0.0.239 virtual interface :7
Following packages from debian repository have been installed for snorby dependencies
libyaml-dev git-core default-jre imagemagick libmagickwand-dev wkhtmltopdf build-essential libssl-dev libreadline-gplv2-dev zlib1g-dev libsqlite3-dev libxslt1-dev libxml2-dev libmysqlclient-dev libmysql++-dev libcurl4-openssl-dev ruby ruby-dev mysql-server imagemagick apache2 libxml2-dev libxslt-dev
Snorby source code have been downloaded from github.

In order to transfer suricata logs to snorby interface we use barnyard
Barnyard collects alerts from Suricata and stuffs them into a database for Snorby front-end interface to display. 
Following packages from debian repository have been installed for baryand dependencies dh-autoreconf libpcap-dev libmysqld-dev libdaq-dev mysql-client autoconf
Baryand source code have been downloaded from github.

All traffic (direct, tor, i2p) coming to loopback interface have been fetched by suricata. Suricata checks traffic by suricata's emerging rules. If check not passed successfully then alert event will be logged in suricata's logs. Then Barnyard collects alerts from Suricata logs and stuffs them into a database for Snorby front-end interface to display. Snorby read logs from database wnd displays it in web interface.

![mod_architecture](images/Readme-Images/arch_Suricata.png)

## NGINX configuration.

## Modsecurity for Hidenservices and direct clearnet published NAT services
ModSecurity is a popular Open-source Web application firewall (WAF). Originally designed as a module for the Apache HTTP Server, it has evolved to provide an array of Hypertext Transfer Protocol request and response filtering capabilities along with other security features across a number of different platforms. It is a free software released under the Apache license 2.0.
![modsecuritylogo](images/Readme-Images/mod-security.png)

In Librerouter we are using Modsecurity as a module in front of Apache Server. 
Modsecurity package have been installed from debian reposirty. Package name: libapache2-modseculty
security2 module have been enabled in apache in order to enable modseculty.
Modseculty have been enabled for following virtual hosts. 

- search.librerouter.net
- social.librerouter.net
- storage.librerouter.net
- email.librerouter.net
- gitlab.librerouter.net
- glype.librerouter.net
- ntop.librerouter.net
- postfix.librerouter.net
- redmine.librerouter.net
- roundcube.librerouter.net
- snorby.librerouter.net
- sogo.librerouter.net
- squidguard.librerouter.net
- trac.librerouter.net
- waffle.librerouter.net
- webconsole.librerouter.net
- conference.librerouter.net
- webmin.librerouter.net

In modseculty we have enabled following free open-source rules.
- OWASP Core Rule Set (in /usr/src/ModSecurityRules/Owasp)
- Comodo Rule Set (/usr/src/ModSecurityRules/Comodo)

We have custom rules for following virtual hosts
- search.librerouter.net  -  There is a need to allow yacysearch.html page
- storage.librerouter.net -  There is a need to allow nextcloud page (favorites, recent)
- waffle.librerouter.net - here is a need to allow controller page 

We use waffle as a GUI interface for monitoring modsecurity activities. Waffle have one primary preinstalled sensor called librerouter to detect all activities.  
waffle.librerouter.net â€“ 10.0.0.238 virtual interface :17

All web traffic (direct, tor, i2p) are coming to modsecurity tool in front of apache server. Before handling requests modsecurity at first checks request by OWASP ans Comodo rules. If check passed successfully then request will be handled as usual, if check is not passed then userâ€™s request will be redirected to defualt web page with error 403 Forbidden.

![mod_architecture](images/Readme-Images/mod_architecture.png)

## TOR configurations.
Tor dns configuration is implemented like this...

### Privoxy and Privacy options for TOR traffic:

![privoxy-rulesets-web](images/Readme-Images/tor-config.gif)


## I2P configuration.

## Multiple Squids (darknet bumping and clearnet ssl NObump) configurations.

 








###HSTS 
https://en.wikipedia.org/wiki/HTTP_Strict_Transport_Security

Problem: when a use uses the google/bing search by a direct query keyword in the browsers
The browser enfoces hsts then the certificate from our redirected yacy fails.
Then we cant inspect the traffic for this big list of domains:
https://cs.chromium.org/chromium/src/net/http/transport_security_state_static.json
We inspect for protecting the browser against exploitation of bugs and attacks.
Who can guaranteed this entities are not doing it?

We inspect the HSTS domains with Snort,Suricata BRO and CLamAV via ICAP CCAP and Squid bumping

The problem is that the redirection we made when the user tries gmail for instance in to local service mailpile fails with multiple browser because hsts.

Why we redirect gmail to mailpile or roundcube? obvious we offer s elfhosted solution better than corporate centralized.

##Squid tuning conf for Privacy : squid.conf 

	- via off
	- forwarded_for off
	- header_access From deny all
	- header_access Server deny all
	- header_access WWW-Authenticate deny all
	- header_access Link deny all
	- header_access Cache-Control deny all
	- header_access Proxy-Connection deny all
	- header_access X-Cache deny all
	- header_access X-Cache-Lookup deny all
	- header_access Via deny all
	- header_access Forwarded-For deny all
	- header_access X-Forwarded-For deny all
	- header_access Pragma deny all
	- header_access Keep-Alive deny all
	-   request_header_access Authorization allow all
	-   request_header_access Proxy-Authorization allow all
	-   request_header_access Cache-Control allow all
	-   request_header_access Content-Length allow all
	-   request_header_access Content-Type allow all
	-   request_header_access Date allow all
	-   request_header_access Host allow all
	-   request_header_access If-Modified-Since allow all
	-   request_header_access Pragma allow all
	-   request_header_access Accept allow all
	-   request_header_access Accept-Charset allow all
	-   request_header_access Accept-Encoding allow all
	-   request_header_access Accept-Language allow all
 	-   request_header_access Connection allow all
	-   request_header_access All deny all
	-   forwarded_for delete
	-   follow_x_forwarded_for deny all
 	-   request_header_access X-Forwarded-For deny all
	-   request_header_access From deny all
	-   request_header_access Referer deny all
	-   request_header_access User-Agent deny all




Iptables are configured on /etc/rc.local script, and from here other scripts can be called to add/delete/modify
activerules.First of all let's go ensure to clean all rules in all tables, for that we do:

**
iptables -X
iptables -F
iptables -t nat -F
iptables -t filter -F
**

Next we do basic rules to allow some traffic to the local services. 
Let's explain why we use a logical bridge interfacehere instead the physical interface.You can observe on this block of 
rules we filter matching also interface, that is **br1**
The use of logical bridge facilitates to use same know at priory 
name for further interfaces, in a way we can call itbr1 and save fixed rules based on that name, and later we can add/remove 
physical interfaces on this bridge, dependingparticual requirements of the enduser.On first stage when we are running 
configuration-script.sh we don't know yet if the enduser will be use some ports or not, what ports are connected to internet 
router and what ports are connected to the internal lan.More than that, eve we don't know if some of these ports are WIFI on 
some wlanN interfaces, and we have no way toknow it at this stage.Then as default initial configuration the br1 interface is 
builded with eth1 and wlan1 ( even those doesn't exist orare unconnected ) by the configuration script.Notice iptables rules 
applied to ANY interface part of a bridge will cause the rule is valid for the whole bridge,in other words, if we place a rule 
for eth1 , will affect to wlan1 too.Later, on wizard.sh script the user will be prompted to tell what physical interfaces ( he 
doesn't know about thelogical ones !! ) he is going to connect and where, as well if required for WIFI id and credentials.On 
this stage br1 may be modified , removing or adding interfaces.The second purpose to work on bridged model , at least on the 
internal lan, is that is required to create some bridgeto use the AP services, where the Librerouter box will act as WIFI 

Access Point for the internal lan.Now the next iptables rules are:
**
iptables -t nat -A PREROUTING -i br1 -p tcp -d 10.0.0.2 -j ACCEPT
iptables -t nat -A PREROUTING -i br1 -p tcp -d 10.0.0.11 -j ACCEPT
iptables -t nat -A PREROUTING -i br1 -p tcp -d 10.0.0.12 -j ACCEPT
iptables -t nat -A PREROUTING -i br1 -p tcp -d 10.0.0.238 -j ACCEPT
iptables -t nat -A PREROUTING -i br1 -p tcp -d 10.0.0.239 -j ACCEPT
iptables -t nat -A PREROUTING -i br1 -p tcp -d 10.0.0.240 -j ACCEPT
iptables -t nat -A PREROUTING -i br1 -p tcp -d 10.0.0.241 -j ACCEPT
iptables -t nat -A PREROUTING -i br1 -p tcp -d 10.0.0.242 -j ACCEPT
iptables -t nat -A PREROUTING -i br1 -p tcp -d 10.0.0.243 -j ACCEPT
iptables -t nat -A PREROUTING -i br1 -p tcp -d 10.0.0.244 -j ACCEPT
iptables -t nat -A PREROUTING -i br1 -p tcp -d 10.0.0.245 -j ACCEPT
iptables -t nat -A PREROUTING -i br1 -p tcp -d 10.0.0.246 -j ACCEPT
iptables -t nat -A PREROUTING -i br1 -p tcp -d 10.0.0.247 -j ACCEPT
iptables -t nat -A PREROUTING -i br1 -p tcp -d 10.0.0.248 -j ACCEPT
iptables -t nat -A PREROUTING -i br1 -p tcp -d 10.0.0.249 -j ACCEPT
iptables -t nat -A PREROUTING -i br1 -p tcp -d 10.0.0.250 -j ACCEPT
iptables -t nat -A PREROUTING -i br1 -p tcp -d 10.0.0.251 -j ACCEPT
iptables -t nat -A PREROUTING -i br1 -p tcp -d 10.0.0.252 -j ACCEPT
iptables -t nat -A PREROUTING -i br1 -p tcp -d 10.0.0.253 -j ACCEPT
iptables -t nat -A PREROUTING -i br1 -p tcp -d 10.0.0.254 -j ACCEPT
**

This block only ensures the internal traffic is accepted, really nothing happens if we remove it while we havenot any further 
rule dening that traffic.Is important to take in mind that iptables runs in the order we enter the rules and once one rule is 
matchedthe next rules are NOT checked.Iptables use -A ( append = put at the end of other existing rules ), -I ( insert, you can 
insert the rule at topor at some position ) and -D ( delete the rule )Next block:

**
iptables -t nat -A PREROUTING -i br1 -p tcp -d 10.0.0.1 --dport 22 -j REDIRECT --to-ports 22
iptables -t nat -A PREROUTING -i br1 -p udp -d 10.0.0.1 --dport 53 -j REDIRECT --to-ports 53
iptables -t nat -A PREROUTING -i br1 -p tcp -d 10.0.0.1 --dport 80 -j REDIRECT --to-ports 80
iptables -t nat -A PREROUTING -i br1 -p tcp -d 10.0.0.1 --dport 443 -j REDIRECT --to-ports 443
iptables -t nat -A PREROUTING -i br1 -p udp -d 10.0.0.2 --dport 53 -j REDIRECT --to-ports 53
iptables -t nat -A PREROUTING -i br1 -p tcp -d 10.0.0.2 --dport 80 -j REDIRECT --to-ports 80
iptables -t nat -A PREROUTING -i br1 -p tcp -d 10.0.0.2 --dport 443 -j REDIRECT --to-ports 443
**

Even the syntax used here is a bit different, really does same, accept the traffic to some ports on theIP 10.0.0.1, redirecting 
to the same port, that is matching that traffic and ignoring next rules in orderin the tables.Now comes a block per each 
service:

**### to squid-i2p ###
iptables -t nat -A OUTPUT     -d 10.191.0.1 -p tcp --dport 80 -j REDIRECT --to-port 3128
iptables -t nat -A PREROUTING -d 10.191.0.1 -p tcp --dport 80 -j REDIRECT --to-port 3128
iptables -t nat -A PREROUTING -i br1 -p tcp -m tcp --sport 80 -d 10.191.0.1 -j REDIRECT --to-ports 3128
**

First line matches all outgoing traffic with destination IP 10.191.0.1 and destination port 80 and redirect itto the port 3128
Second line does same but with all originated traffic in the box ( or injected traffic as ip_forwarding=1 )Third line does same 
but for inverse traffic on the bridge 1 incoming traffic from port 80 and destination 10.191.0.1The result is all outgoing 
traffic on any interface to 10.191.0.1:80, al traffic passing through the Librerouter withdestination 10.191.0.1:80 and all 
traffic in bridge1 with destination 10.191.0.1 and source port 80 , all them goesredirected to port 3128

**#### ssh to tor socks proxy ###
iptables -t nat -A PREROUTING -i br1 -p tcp -d 10.0.0.0/8 --dport 22 -j REDIRECT --to-ports 9051
**
The traffic on the bridge to destination internal lan and destination port 22 ( SSH ) is redirected to theTor Socks5 service. 
Well Tor is not a Proxy like a HTTP Proxy, but is a SOCKS, so don't come confuse withthe comment "ssh to tor socks proxy"

This causes all traffic from the internal lan ( same host or different host ) and destination port 22 is redirectedto the Tor 
service.

### to squid-tor
** iptables -t nat -A PREROUTING -i br1 -p tcp -d 10.0.0.0/8 -j DNAT --to 10.0.0.1:3129
### to squid http 
###
** 
iptables -t nat -A PREROUTING -i br1 -p tcp -m ndpi --http -j REDIRECT --to-ports 3130
iptables -t nat -A PREROUTING -i br1 -p tcp --dport 80 -j DNAT --to 10.0.0.1:3130
### to squid https ### 
** 
iptables -t nat -A PREROUTING -i br1 -p tcp --dport 443 -j REDIRECT --to-ports 3131
**
These does similar to anterior, but redirecting to SQUID ports 3129, 3130 and 3131  

**### iptables nat###
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
**
Here is new rule called MASQUERADE that is focused to NAT the traffic in a way a packet ( remember we have ip_forward=1 
)comming into br1 with origination ip Host1 would reach the outside world as from Host1. Then of course the other endwill not 
know where to respond to that packet. We need to do MASQUERADE as this packed that doesn't matched any earlyrule goes to the 
eth0 ( our internet connection as default ) and go to the external world as from our public IP connection( our internet 
connection ). When response packect comes back the router will do translate it again to the Librerouter IPon eth0

**### Blocking ICMP from LAN_TO_WAN and from WAN_TO_LAN/ROUTER ###
iptables -A FORWARD -p ICMP -j DROP
iptables -A INPUT -p icmp -s 10.0.0.0/8 ! -d 10.0.0.0/8 -j DROP**  

The first line just drop forwarding ICMP ( ping ) traffic from one interface to other different interface or IP.The second line drops all ICMP traffic comming not from the internal lan and with destination internal lan, so internal lancan be only pinged from the internal lan.This allows pinging to wan , that is pinging to the external world, but cuts discovering from any host that is not in theinternal lan via ping.

**### Blocking IPsec (All Directions) 
###
**
iptables -A INPUT -m ndpi --ip_ipsec -j DROP
iptables -A OUTPUT -m ndpi --ip_ipsec -j DROP
iptables -A FORWARD -m ndpi --ip_ipsec -j DROP
**
We block all IPSEC traffic in all directions, all this traffic is dropped  

**### Blocking DNS request from client to any servers other than librerouter ###
iptables -A INPUT -i br1 -m ndpi --dns  -d 10.0.0.2 -j ACCEPT 
iptables -A INPUT -i br1 -m ndpi --dns  -d 10.0.0.1 -j ACCEPT
iptables -A INPUT -i br1 -m ndpi --dns  -d 0/0 -j DROP 


We don't allow any traffic for DNS services with destination different of 10.0.0.1, in a way all domains must be resolvedin the Librerouter box and NEVER directly by external DNS servers.Finally .... we just drop all other forwarded traffic that didn't matched the previous rules with :

**iptables -P FORWARD DROP**


# MTA and RDNS #

Most SMTP servers requires reverse DNS resolution to accept incoming emails. 
The solution is to build a VPN tunnel and provide a public IP where we are able to set direct as well as ARPA resolution.

There two parts involved, the first one is the tunnel itself and the second one is the routing of specific traffic only through this tunnel.

The main requirements are:
1. Tunnel public IP must be reachable and routable from the internet
2. Tunnel public IP must provide RDSN pointed to name same domain as direct domain to that IP
3. Tunnel provide SHA key authentication.

To build the tunnel we use openvpn, with a really simple configuration as client:

* remote vpn.zonnox.com # This the tunnel provider
* proto udp             # We are going to use the standard UDP, see later how to use TCP
* port 1194 
* comp-lzo              # No bad idea to enable compression
* log-append /var/log/openvpn.log
* dev tun
* persist-key
* client
* cipher BF-CBC
* ca /etc/openvpn/certs/ca.crt
* cert /etc/openvpn/certs/session.crt
* key /etc/openvpn/keys/session.key
* 


The files ca.crt , session.crt and session.key mus be provide from the VPN service.

Then the server based on Client credentials we give us a fixed public IP and route it to us from the Internet.

Special mention to those sites where for some reason we are unable to reach UDP at all or standard 1194 port to connect to the VPN server, in this case
we can configure our client to use TCP ( at cost of performance ) and this VPN server is also listening on TCP port 443. 

For those cases where we need to verify the tunnel and build accordly to our network capabilities and permisions is not bad idea to run a script to
force the tunnel even if UDP or port 1194 are not reachable.

Once the tunnel is up, we are able to see our public IP if we issue 'ifconfig' command.

The second part, we need to route some traffic through this tunnel, and leave rest of traffic as is.
The criteria is:

We are going to route to the tunnel all outgoing traffic with destination port 25 ( SMTP )
We need also to route to the tunnel all incoming traffic ( from the other eth or wlan ) that has destination the tunnel public IP, in a way we are 
reachable also from Internet to our public IP in the tunnel.

We do that here:

* ip route add default via 81.19.162.169 dev tun0 table SMTP
* ip rule add from all fwmark 0x1 lookup SMTP
* iptables -t mangle -I PREROUTING -p tcp --dport 25 -j MARK --set-mark 1
* iptables -t mangle -A OUTPUT -p tcp --dport 25 -j MARK --set-mark 1
* iptables -t -nat -A POSTROUTING -p tcp --dport 25 -j SNAT --to-source $TUNNEL_PUBLIC_IP 
* iptables -t mangle -A OUTPUT -s $TUNNEL_PUBLIC_IP -j MARK --set-mark 1


The last rule ensures we can be reachable from the internet, otherwise we are going to get traffic on tun0 and use other interface
to respond back, in asimetric interface traffic that can cause the connection is not stablished.

We can check our SMTP routing table with 'ip route show table SMTP'

Notice sometime the tunnel for any reason can comes down ( i.e. if you lost your internet over the TTL ) and then you LOST 
the routing table.
To avoid this inconvenience the routing table is re-builded every 2 minutes from cron. 





