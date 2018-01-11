#Librerouter GUI (early draft)

The porposal by now is to have a based sliders button based GUI
Every slider will represent on off
The GUI need to be basic for non technical people but have to be prepared by method drill in to deep to be able to show every time in the GUI more detailed configuration capabilities when the user drills in , in any of the option.

Every slider on or off will directly execute a matrix of scripts that will reconfigure multiple places configurations files and system paramenters.  A single option can affect the entire system and diferent engines and subengines. In that way the script will check how other options in the system are configured before start the modification of the paramenter and configuration files.

![click and drill](https://cloud.githubusercontent.com/assets/17382786/17436107/61e300bc-5b15-11e6-8ae4-b650577fb9a6.png)

##FUTURE WIZARDS AND GUIS

This wizard should ask the customer about and is pending in the project to be developed:

 -a) Do you want your protect your privacy or just user Librerouter services? if yes then mode bridge if not then mode equals server.
 -b) Mode Transparent firewall Bridge:
 -     Lets configure the Internet access (WAN)
 -     Do you want to conect your Librerouter to your Internet router via cable or WLAN?
 -         if WLAN
Please specify your internet router SSID Please specify your encryption methods WPA or WPA2 WEP not allowed no encryption not allowed Please specifiy your SSID password The daemon should check the conection getting up If not especify error conditions

if Cable:

*If Cable and DHCP:
Please specify if you would use fix IP or DHCP client? If DHCP Then setup dhcp client in the interface and try to receive IP The daemon should check the conection getting up If not especify error conditions

If Cable and FIX IP address:
*Please provide the IP address Please provide the default GW Please provide the DNS server Trying ping against the IPs If correct finish The daemon should check the conections answers If not especify error conditions

Lets configure the Internal access (LAN Intranet)
 -Do you want to setup your internal protected network via cable or WLAN?

If WLAN then:
 -Please specify your internal new WLAN name SSID Please specifiy your SSID WPA2 CCMP password The daemon should check the connection getting up If not especify error conditions The IP addresses are 10.0.0.1 forced (if the guy another then hack the box)

if Cable then:
 -Please be aware we use this internal range: 10.0.0.100 to 200 Gateway 10.0.0.1 and DNS
 -Please plug a cable Detecting link Link up Now your connected

c) Mode Server only WAN external bridge will be used and then all WLAN and ETH will be all 4 interfaces in the same Bridge NIC logical interface.Do you want to use a cable or want Librerouter connect to your router or switch?

if WLAN

Please specify your internet router SSID Please specify your encryption methods WPA or WPA2 WEP not allowed no encryption not allowed Please specifiy your SSID password The daemon should check the conection getting up If not especify error conditions

if Cable:
If Cable and DHCP:
Please specify if you would use fix IP or DHCP client? If DHCP Then setup dhcp client in the interface and try to receive IP The daemon should check the connection getting up If not specify error conditions

If Cable and FIX IP address:
Please provide the IP address Please provide the default GW Please provide the DNS server Trying ping against the IPs If correct finish The daemon should check the connections answers If not specify error conditions 

mode 2

 Do you want to use a cable or want librerouter connect to your router or switch?

if WLAN

Please specify your internet router SSID Please specify your encryption methods WPA or WPA2 WEP not allowed no encryption not allowed Please specifiy your SSID password The daemon should check the conection getting up If not especify error conditions

if Cable:

If Cable and DHCP:

Please specify if you would use fix IP or DHCP client? If DHCP Then setup dhcp client in the interface and try to receive IP The daemon should check the connection getting up If not specify error conditions

If Cable and FIX IP address:

Please provide the IP address Please provide the default GW Please provide the DNS server Trying ping against the IPs If correct finish The daemon should check the connections answers If not specify error conditions 



#WAN Wizard
Following is the WAN connection wizard, where the user need to select WAN settings from either the wired or wireless connection.
![wan_wizard_pic](https://github.com/Librerouter/Librekernel/blob/gh-pages/images/wan_wizard.png)

Following is the WAN connection wizard for wired connection. User need to select IP address setting from DHCP or static IP.
![wan_wizard_pic-2](https://github.com/Librerouter/Librekernel/blob/gh-pages/images/wan_wizard-2.png)

For Static IP address settings, user to provide all the required details like IP address, netmask, gateway and DNS servers.
![wan_wizard_pic-3](https://github.com/Librerouter/Librekernel/blob/gh-pages/images/wan_wizard-3.png)

#WLAN WAN Wizard
Following is the WLAN WAN connection wizard, where the user need to provide SSID, passphrase for a wireless network to get connected.
User also need to choose between DHCP and static IP address settings
![wlan_wan_wizard_pic](https://github.com/Librerouter/Librekernel/blob/gh-pages/images/wlan_wan_wizard.png)

For Static IP address settings, user need to provide the required details like IP address, netmask, gateway and DNS servers.
![wlan_wan_wizard_pic-2](https://github.com/Librerouter/Librekernel/blob/gh-pages/images/wlan_wan_wizard_2.png)
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

#Apps Wizard
Following is the Apps wizard, where the user need to enable/disable apps.
![apps_wizard_pic](https://github.com/Librerouter/Librekernel/blob/gh-pages/images/apps-wizard.png)

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

#SSL Wizard
Following is the ssl wizard, where the user need to enable/disable ssl bumping.
![ssl_wizard_pic](https://raw.githubusercontent.com/Librerouter/Librekernel/gh-pages/images/ssl-wizard.png)

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

#Security Firewall Wizard
Following is the Security Firewall configuration wizard, where the user need to enable/disable firewall configuration items.
![security_fw_wizard_pic](https://github.com/Librerouter/Librekernel/blob/gh-pages/images/security_firewall_wizard.png)
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

#Firewall Menu Wizard
Following is the Firewall Menu wizard, where the user need to select the category of firewall according to the requirement.
To Eric: Some of the words were not recognizable from the scanned images sent by Eric in an email. We have kept “….” on such places inside the below image.
![fw_menu_wizard_pic](https://github.com/Librerouter/Librekernel/blob/gh-pages/images/firewall_menu_wizard.png)
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

#Categories of Firewall Wizard
Following is the Firewall categories wizard, where the user can go through different categories of Firewall.
![fw_menu_wizard_pic](https://github.com/Librerouter/Librekernel/blob/gh-pages/images/categories_of_firewall.png)
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

#Security Engines Wizard
Following is the Security Engines wizard, where the user need to enable/disable security engines according to the need.
![sec_engines_wizard_pic](https://github.com/Librerouter/Librekernel/blob/gh-pages/images/security_engines_wizard.png)
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

#Main Menu after Wizard
Following is the Main menu after wizard.
![main_menu_after_wizard_pic](https://github.com/Librerouter/Librekernel/blob/gh-pages/images/main_menu_after_wizard.png)
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

#Privacy Firewall Wizard
Following is the Privacy Firewall wizard.
![after_wizard_privacy_firewall_pic](https://github.com/Librerouter/Librekernel/blob/gh-pages/images/after_wizard_privacy_firewall.png)
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

#WebUI Architecture
The following is the initial diagram for how the WEB UI will be built
![webui_arch_pic](https://github.com/Librerouter/Librekernel/blob/gh-pages/images/librerouter-ui.png)
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
