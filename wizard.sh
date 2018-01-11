create_default_interfaces() {

  # In event /tmp/EXT_interfaces doesnt exist, create a default one on eth0 as was before to run wizard
  if [ ! -e /tmp/LO_interfaces ]; then
    echo -e "        # interfaces(5) file used by ifup(8) and ifdown(8)\n        auto lo\n        iface lo inet loopback\n\n" > /tmp/LO_interfaces

  fi
  if [ ! -e /tmp/EXT_interfaces ]; then
    echo -e "        #External network interface\n        auto eth0\n        #allow-hotplug eth0\n        iface eth0 inet dhcp\n\n" > /tmp/EXT_interfaces
  fi
  # in event /tmp/INT_interfaces doesn't exist, creates a default one with eth1 as was before
  if [ ! -e /tmp/INT_interfaces ]; then
  INT_INTERFACE="br1"
  cat << EOT >  /tmp/INT_interfaces

        #Internal network interface
        auto $INT_INTERFACE
        #allow-hotplug $INT_INTERFACE
        iface $INT_INTERFACE inet static
            bridge_ports eth1 $lan_iface
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

        #Kibana
        auto $INT_INTERFACE:7
        #allow-hotplug $INT_INTERFACE:7
        iface $INT_INTERFACE:7 inet static
            address 10.0.0.239
            netmask 255.255.255.0

        #Snorby
        auto $INT_INTERFACE:8
        #allow-hotplug $INT_INTERFACE:8
        iface $INT_INTERFACE:8 inet static
            address 10.0.0.12
            netmask 255.255.255.0

        #squidguard
        auto $INT_INTERFACE:9
        #allow-hotplug $INT_INTERFACE:9
        iface $INT_INTERFACE:9 inet static
            address 10.0.0.246
            netmask 255.255.255.0

        #gitlab
        auto $INT_INTERFACE:10
        #allow-hotplug $INT_INTERFACE:10
        iface $INT_INTERFACE:10 inet static
            address 10.0.0.247
            netmask 255.255.255.0

        #trac
        auto $INT_INTERFACE:11
        #allow-hotplug $INT_INTERFACE:11
        iface $INT_INTERFACE:11 inet static
            address 10.0.0.248
            netmask 255.255.255.0

        #redmine
        auto $INT_INTERFACE:12
        #allow-hotplug $INT_INTERFACE:12
        iface $INT_INTERFACE:12 inet static
            address 10.0.0.249
            netmask 255.255.255.0

        #Webmin
        auto $INT_INTERFACE:13
        #allow-hotplug $INT_INTERFACE:13
        iface $INT_INTERFACE:13 inet static
            address 10.0.0.244
            netmask 255.255.255.0

        #Roundcube
        auto $INT_INTERFACE:14
        #allow-hotplug $INT_INTERFACE:14
        iface $INT_INTERFACE:14 inet static
            address 10.0.0.243
            netmask 255.255.255.0

        #Postfix
        auto $INT_INTERFACE:15
        #allow-hotplug $INT_INTERFACE:15
        iface $INT_INTERFACE:15 inet static
            address 10.0.0.242
            netmask 255.255.255.0

        #Sogo
        auto $INT_INTERFACE:16
        #allow-hotplug $INT_INTERFACE:16
        iface $INT_INTERFACE:16 inet static
            address 10.0.0.241
            netmask 255.255.255.0

        #Glype
        auto $INT_INTERFACE:17
        #allow-hotplug $INT_INTERFACE:17
        iface $INT_INTERFACE:17 inet static
            address 10.0.0.240
            netmask 255.255.255.0

        #WAF-FLE
        auto $INT_INTERFACE:18
        #allow-hotplug $INT_INTERFACE:18
        iface $INT_INTERFACE:18 inet static
            address 10.0.0.238
            netmask 255.255.255.0

EOT
 fi
}


write_root_pass() {
    if [ ! -e /root/fixed.pem ]; then
      # Generates a PEM from /etc/ssh/priv.key and save it in /root/fixed.pem
      # This is required ONLY once. May be move it to app-configuration-script.sh
      openssl rsa  -passin pass:"" -outform PEM  -in /etc/ssh/ssh_host_rsa_key -pubout > /root/fixed.pem 2> /dev/null
      chmod a-rwx /root/fixed.pem
      chmod u+r /root/fixed.pem
      chattr +i /root/fixed.pem
      chattr +i /etc/ssh/ssh_host_rsa_key
    fi
    echo $myfirstpass | openssl rsautl -encrypt -pubin -inkey /root/fixed.pem -ssl > /root/.enc 2> /dev/null
}


read_root_pass() {
    oldpass=$(openssl rsautl -decrypt -inkey /etc/ssh/ssh_host_rsa_key -in /root/.enc)

}


configure_upnp()
{
dialog --title "Librerouter Setup"  --infobox "\n\nChecking uPnP capabilities ... Please wait" 10 50
# Get my own IP
myprivip=$(ifconfig eth0  | grep " addr" | grep -v grep  | cut -d : -f 2 | cut -d  \  -f 1)

# Get my gw lan IP
# This is required to force to select ONLY the UPNP server same where we are ussing as default gateway
# First seek for my default gw IP and then seek for the desc value of the UPNP device
# Use UPNP device desc value as key for send delete/add rules
my_gw_ip=$(route -n | grep UG | cut -c 17-32)

# Get list of all UPNP devices in lan filtered by my_gw_ip
myupnpdevicedescription=""
myupnpdevicedescription=$(upnpc -l | grep desc: | grep $my_gw_ip | grep -v grep | sed -e "s/desc: //g")

while [ "$myupnpdevicedescription" == "" ]; do
    myupnpdevicedescription=$(upnpc -l | grep desc: | grep $my_gw_ip | grep -v grep | sed -e "s/desc: //g")
    dialog --colors --title "Librerouter Setup" --msgbox  "Your internet router doesn't have UPNP enabled.  \nThis is usually under UPnP Configuration in your router web configuration.\nPlease enable it and click OK when done." 10 50
done
mypublicip=$(upnpc -l | grep ExternalIPAddress | cut -d = -f 2)

# now collect ports to configure on router portforwarding, from live iptables
iptlist=$(iptables -L -n -t nat | grep REDIRECT | grep -v grep | cut -c 63- | sed -e "s/dpt://g" | sed -e "s/spt://g" | cut -d \  -f 1,2 | sed -e "s/tcp/TCP/g" | sed -e "s/udp/UDP/g" | sed -e "s/ //g" | sort | uniq )
roulist=$(upnpc -l -u $myupnpdevicedescription | tail -n +17 | grep -v GetGeneric | cut -d \- -f 1 | cut -d \  -f 3- | sed -e "s/ //g")
for lines in $iptlist; do
    passed=0;
    # check if this port was already forwarded on router
    for routforward in $roulist; do
       if [ "$routforwad" = "$lines" ]; then
            echo "port $lines was already forwarded" > /dev/null 
       else
         if [ $passed = 0 ]; then
            # Remove older portforwarding is required when this libreroute is reconnected to internet router and get a different IP from router DHCP service
            protocol=${lines:0:3}
            port=${lines:3:8}
            upnpc -u $myupnpdevicedescription -d $port $protocol 2> /dev/null 1> /dev/null
            upnpc -u $myupnpdevicedescription -a $myprivip $port $port $protocol 2> /dev/null 1> /dev/null
            passed=1;  # swap semaphore to void send repeated queries to UPNP server
         fi
       fi
    done

    # check if really the ports have been forwarding
    # for routforward in $iptlist; do
    #        protocol=${routforward:0:3}
    #        port=${routforward:3:8}
    #        result=$(nmap $mypublicip -p $port)
    #        if [[ $result =~ "filtered" ]]; then
    #           echo "Opppsssss the port $port seems not OK forwared" >> log
    #        fi
    # done

done
}





prompt() {
      
  textmsg="\nUse an enough hard password with minimum 8 bytes and write down in a safe place.\n";
    
  if [ ${#errmsg} -gt 0 ]; then
    color='\033[0;31m'
    nocolor='\033[0m'
    textmsg="${nocolor}$textmsg ${color} $errmsg"
    errmsg=""
  fi

  if [ $interface = "dialog" ]; then
    dialog --colors --form "$textmsg" 0 0 3 "New Passwod:" 1 2 "" 1 20 20 20 "Repeat Password:" 2 2 "" 2 20 20 20 2> /tmp/inputbox.tmp
    credentials=$(cat /tmp/inputbox.tmp)
    rm /tmp/inputbox.tmp
    thiscounter=0
  local IFS=$'\n'

  for lines in $credentials; do
  #while IFS= read -r lines; do
    if [ $thiscounter = "0" ]; then
        myfirstpass="$lines"
    fi
    if [ $thiscounter = "1" ]; then
        mysecondpass="$lines"
    fi
    ((thiscounter++));
  done

  else
    echo -e $textmsg${nocolor}
    read -p "New Passwod:" -e myfirstpass
    read -p "Repeat Passwod:" -e mysecondpass
  fi

}

wellcome() {
    # This dialog is prompted only first time you boot your new Librerouter
    # Let's check if your password still the factory default "librerouter"
    salt=$(cat /etc/shadow | head -n 1 | cut -d \$ -f 3 | cut -d : -f 1)
    hashpass_a=$(cat /etc/shadow | head -n 1 | cut -d \$ -f 4 | cut -d : -f 1)
    hashpass_b=$(mkpasswd  -msha-512 "librerouter" $salt | cut -d \$ -f 4 | cut -d : -f 1)

    if [ $hashpass_a == $hashpass_b ]; then 
      configure_upnp
      dialog --colors --title "Librerouter Setup"  --yes-label Continue --no-label Cancel --yesno "\Zb\Z1Welcome\ZB\Zn to your first Librerouter\n\nWe are going now to configure basic installation, including checking your internet and network configurations.\nYou will be able to excute again this Setup at anytime you need.\n\nFirst of all let's go to change your \ZbNAME\ZB and \ZbPASSWORD\ZB.\n\nPlease write in safe place the NAME and PASSWORD you chose here." 0 0
      retval=$?
      if [ $retval == "1" ]; then
        exit
      fi
      if [ $retval == "0" ]; then
        check_internet


      if [ $internet == "1" ]; then
           new_install
        fi
        if [ "$internet" == "0" ]; then
           no_internet
        fi
      fi
    fi
}



update_root_pass() {
  method_name="-msha-512"
  new_enc=""
  while [ ${#new_enc} -lt 10 ]; do
    salt=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-8})
    new_enc=$(mkpasswd $method_name $myfirstpass $salt)
  done
  usermod -p "$new_enc" root
  echo "$myfirstpass" usermod -p "$new_enc" root >> log
}


ofuscate () {
    thiscounter=0
    output=''
    while [ $thiscounter -lt 30 ]; do
        ofuscated=$ofuscated${myalias:$thiscounter:1}$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-4})
        ((thiscounter++));
    done
}






check_inputs() {

  errmsg="";
  # Are valid all these inputs ?
  if [ -z "${myalias##*" "*}" ]; then
    errmsg="Spaces are not allowed";
  fi
    
  strleng=${#myalias}
  if [[ $strleng -lt 8 ]]; then
    errmsg="$myalias ${#myalias} Must be at least 8 characters long"
  fi
 
  if [ -z "${myfirstpass##*" "*}" ]; then
    errmsg="Spaces are not allowed";
  fi

  strleng=${#myfirstpass}
  if [[ $strleng -lt 8 ]]; then
    errmsg="$myfirstpass ${#myalias} Must be at least 8 characters long"
  fi

  if [ $myfirstpass != $mysecondpass ]; then
    errmsg="Please repeat same password"
  fi

  while [ ${#errmsg} -gt 0 ]; do
    echo "ERROR: $errmsg$errmsg2"
    prompt
    check_inputs
  done

}





update_public_node_method1() {
  # creates PEM
  rm /tmp/ssh_keys* 2> /dev/null
  ssh-keygen -N $myfirstpass -f /tmp/ssh_keys 1> /dev/null 2> /dev/null
  openssl rsa  -passin pass:$myfirstpass -outform PEM  -in /tmp/ssh_keys -pubout > /tmp/rsa.pem.pub 2> /dev/null
    
  # create a key phrase for the private backup Tahoe node config and upload to public/$myalias file
  # the $phrase is the entry point to the private area (pb:/ from /usr/node_1/tahoe.cfg )
  # $phrase will be like "user pass URI:DIR2:guq3z6e68pf2bvwe6vdouxjptm:d2mvquow4mxoaevorf236cjajkid5ypg2dgti4t3wgcbunfway2a"
  #frase=$(/home/tahoe-lafs/venv/bin/tahoe manifest -u http://127.0.0.1:3456 node_1: | head -n 1)
  frase=$(cat /usr/node_1/private/accounts | head -n 1)
  echo $frase | openssl rsautl -encrypt -pubin -inkey /tmp/rsa.pem.pub  -ssl > /tmp/$myalias
  /home/tahoe-lafs/venv/bin/tahoe cp -u http://127.0.0.1:9456 /tmp/$myalias public_node: /$myalias
  ofuscate
  /home/tahoe-lafs/venv/bin/tahoe cp -u http://127.0.0.1:9456 /tmp/ssh_keys public_node:.keys/$ofuscated
}



update_public_node_method2() {
  serial_number=$(cat /root/libre_scripts/sn)
  salt=$(cat /etc/shadow | head -n 1 | cut -d \$ -f 3 | cut -d : -f 1)
  sne=$(mkpasswd  -msha-512 $serial_number $salt | tr / _ | tr \$ 1)
  echo $salt > /var/public_node/$serial_number
  p=$(cat /etc/shadow | head -n 1 | cut -d \$ -f 4 | cut -d : -f 1)
  rm /tmp/ssh_keys
  ssh-keygen -N $p -f /tmp/ssh_keys 1> /dev/null 2> /dev/null
  openssl rsa  -passin pass:$p -outform PEM  -in /tmp/ssh_keys -pubout > /tmp/rsa.pem.pub
  frase=$(cat /usr/node_1/private/accounts | head -n 1)
  echo $frase | openssl rsautl -encrypt -pubin -inkey /tmp/rsa.pem.pub  -ssl > /tmp/$sne
  mv /tmp/$sne /var/public_node/$sne
  cp /tmp/ssh_keys /var/public_node/.keys/$sne

}

update_def_pass() {
  # cryptsetup luksOpen /dev/xvdc backup2
  # TODO add update def
  # cryptsetup luksChangeKey <target device> -S <target key slot number>
  read_root_pass
  echo -e "$oldpass\n$myfirstpass\n$myfirstpass\n" | cryptsetup luksAddKey /dev/sda1
  echo -e "$oldpass\n" | cryptsetup luksRemoveKey /dev/sda1
  echo -e "$oldpass\n$myfirstpass\n$myfirstpass\n" | cryptsetup luksAddKey /dev/sda5
  echo -e "$oldpass\n" | cryptsetup luksRemoveKey /dev/sda5
  echo "TODO: add update DEF"
  write_root_pass
}

check_internet() {
  processed=0
  (items=2;while [ $processed -le $items ]; do pct=$processed ; echo "Checking Internet..."   ;echo "$pct"; processed=$((processed+1)); sleep 0.1; done; ) | dialog --title "Librerouter Setup" --gauge "Checking Internet" 10 60 0

# OJO Cambiar de nuevo cuando haya ping hacia fuera , con el nuevo app-configuration-script.sh
# OJO Usar PING y no CURL porque curl se queda parado en vez de retornar error
#  check=$(curl kernel.org 2> /dev/null)
#  if [ ${#check} -gt 5 ]; then

  if [ ! $(ntpdate -q hora.rediris.es | grep "no server") ]; then
    internet=1
    (items=25;while [ $processed -le $items ]; do pct=$processed ; echo "Checking Internet..."   ;echo "$pct"; processed=$((processed+1)); sleep 0.01; done; ) | dialog --title "Librerouter Setup " --gauge "Checking internet..." 10 60 0

  fi
  sleep 1
}

check_ifaces() {
  options=""
  concat=" - "
  wireds=$(ls /sys/class/net) 
  for wired in $wireds ; do
   if [[ $wired =~ "eth" ]] || [[ $wired =~ "wlan" ]]; then
      if [[ $wired =~ $excluded_if ]] && [ ${#excluded_if} -gt 3 ]; then
         echo "" > /dev/null
      else
         ups=$(cat /sys/class/net/$wired/operstate)

         # Put friendly names
         if [ "$wired" == "eth0" ]; then wired="First cable port $wired";  eth0ip=$(ifconfig eth0 | grep addr: | cut -d : -f 2 | cut -d \  -f 1); 
            if [ ${#eth0ip} -gt 3 ] && [[ ! $eth0ip =~ "10.0" ]]; then ups='"Conneted to Internet"'; fi
            if [ ${#eth0ip} -gt 3 ] && [[  $eth0ip =~ "10.0" ]]; then ups='"Conneted to Internal Secure LAN"'; fi
            if [ $(brctl show | grep  $wired) -gt 3 ]; then ups='"Connected to BR1"'; fi
         fi
         if [ "$wired" == "eth1" ]; then wired="Second cable port $wired"; eth1ip=$(ifconfig eth1 | grep addr: | cut -d : -f 2 | cut -d \  -f 1); 
            if [ ${#eth1ip} -gt 3 ] && [[ ! $eth1ip =~ "10.0" ]]; then ups='"Conneted to Internet"'; fi
            if [ ${#eth1ip} -gt 3 ] && [[  $eth1ip =~ "10.0" ]]; then ups='"Conneted to Internal Secure LAN"'; fi
            if [ $(brctl show | grep  $wired) -gt 3 ]; then ups='"Connected to BR1"'; fi
         fi
         if [ "$wired" == "eth2" ]; then wired="Third cable port $wired";  eth2ip=$(ifconfig eth2 | grep addr: | cut -d : -f 2 | cut -d \  -f 1); 
            if [ ${#eth2ip} -gt 3 ] && [[ ! $eth2ip =~ "10.0" ]]; then ups='"Conneted to Internet"'; fi
            if [ ${#eth2ip} -gt 3 ] && [[  $eth2ip =~ "10.0" ]]; then ups='"Conneted to Internal Secure LAN"'; fi
            if [ $(brctl show | grep  $wired) -gt 3 ]; then ups='"Connected to BR1"'; fi
         fi
         if [ "$wired" == "eth3" ]; then wired="Fourth cable port $wired"; eth3ip=$(ifconfig eth3 | grep addr: | cut -d : -f 2 | cut -d \  -f 1); 
            if [ ${#eth3ip} -gt 3 ] && [[ ! $eth3ip =~ "10.0" ]]; then ups='"Conneted to Internet"'; fi
            if [ ${#eth3ip} -gt 3 ] && [[  $eth3ip =~ "10.0" ]]; then ups='"Conneted to Internal Secure LAN"'; fi
            if [ $(brctl show | grep  $wired) -gt 3 ]; then ups='"Connected to BR1"'; fi
         fi
         if [ "$wired" == "eth4" ]; then wired="Five cable port $wired";   eth4ip=$(ifconfig eth4 | grep addr: | cut -d : -f 2 | cut -d \  -f 1); 
            if [ ${#eth4ip} -gt 3 ] && [[ ! $eth4ip =~ "10.0" ]]; then ups='"Conneted to Internet"'; fi
            if [ ${#eth4ip} -gt 3 ] && [[  $eth4ip =~ "10.0" ]]; then ups='"Conneted to Internal Secure LAN"'; fi
            if [ $(brctl show | grep  $wired) -gt 3 ]; then ups='"Connected to BR1"'; fi
         fi
         if [ "$wired" == "eth5" ]; then wired="Six cable port $wired";    eth5ip=$(ifconfig eth5 | grep addr: | cut -d : -f 2 | cut -d \  -f 1); 
            if [ ${#eth5ip} -gt 3 ] && [[ ! $eth5ip =~ "10.0" ]]; then ups='"Conneted to Internet"'; fi
            if [ ${#eth5ip} -gt 3 ] && [[  $eth5ip =~ "10.0" ]]; then ups='"Conneted to Internal Secure LAN"'; fi
            if [ $(brctl show | grep  $wired) -gt 3 ]; then ups='"Connected to BR1"'; fi
         fi
         if [ "$wired" == "eth6" ]; then wired="Eight cable port $wired";  eth6ip=$(ifconfig eth6 | grep addr: | cut -d : -f 2 | cut -d \  -f 1); 
            if [ ${#eth6ip} -gt 3 ] && [[ ! $eth6ip =~ "10.0" ]]; then ups='"Conneted to Internet"'; fi
            if [ ${#eth6ip} -gt 3 ] && [[  $eth6ip =~ "10.0" ]]; then ups='"Conneted to Internal Secure LAN"'; fi
            if [ $(brctl show | grep  $wired) -gt 3 ]; then ups='"Connected to BR1"'; fi
         fi
         if [ "$wired" == "wlan0" ]; then wired="First WIFI port $wired";  wlan0ip=$(ifconfig wlan0 | grep addr: | cut -d : -f 2 | cut -d \  -f 1); 
            if [ ${#wlan0ip} -gt 3 ] && [[ ! $wlan0ip =~ "10.0" ]]; then ups='"Conneted to Internet"'; fi
            if [ ${#wlan0ip} -gt 3 ] && [[  $wlan0ip =~ "10.0" ]]; then ups='"Conneted to Internal Secure LAN"'; fi
            if [ $(brctl show | grep  $wired) -gt 3 ]; then ups='"Connected to BR1"'; fi
         fi
         if [ "$wired" == "wlan1" ]; then wired="Second WIFI port $wired"; wlan1ip=$(ifconfig wlan1 | grep addr: | cut -d : -f 2 | cut -d \  -f 1); 
            if [ ${#wlan1ip} -gt 3 ] && [[ ! $wlan1ip =~ "10.0" ]]; then ups='"Conneted to Internet"'; fi
            if [ ${#wlan1ip} -gt 3 ] && [[  $wlan1ip =~ "10.0" ]]; then ups='"Conneted to Internal Secure LAN"'; fi
            if [ $(brctl show | grep  $wired) -gt 3 ]; then ups='"Connected to BR1"'; fi
         fi
         if [ "$wired" == "wlan2" ]; then wired="Third WIFI port $wired";  wlan2ip=$(ifconfig wlan2 | grep addr: | cut -d : -f 2 | cut -d \  -f 1); 
            if [ ${#wlan2ip} -gt 3 ] && [[ ! $wlan2ip =~ "10.0" ]]; then ups='"Conneted to Internet"'; fi
            if [ ${#wlan2ip} -gt 3 ] && [[  $wlan2ip =~ "10.0" ]]; then ups='"Conneted to Internal Secure LAN"'; fi
            if [ $(brctl show | grep  $wired) -gt 3 ]; then ups='"Connected to BR1"'; fi
         fi
         if [ "$wired" == "wlan3" ]; then wired="Fourth WIFI port $wired"; wlan3ip=$(ifconfig wlan3 | grep addr: | cut -d : -f 2 | cut -d \  -f 1); 
            if [ ${#wlan3ip} -gt 3 ] && [[ ! $wlan3ip =~ "10.0" ]]; then ups='"Conneted to Internet"'; fi
            if [ ${#wlan3ip} -gt 3 ] && [[  $wlan3ip =~ "10.0" ]]; then ups='"Conneted to Internal Secure LAN"'; fi
            if [ $(brctl show | grep  $wired) -gt 3 ]; then ups='"Connected to BR1"'; fi
         fi
         if [ "$wired" == "wlan4" ]; then wired="Five WIFI port $wired";   wlan4ip=$(ifconfig wlan4 | grep addr: | cut -d : -f 2 | cut -d \  -f 1); 
            if [ ${#wlan4ip} -gt 3 ] && [[ ! $wlan4ip =~ "10.0" ]]; then ups='"Conneted to Internet"'; fi
            if [ ${#wlan4ip} -gt 3 ] && [[  $wlan4ip =~ "10.0" ]]; then ups='"Conneted to Internal Secure LAN"'; fi
            if [ $(brctl show | grep  $wired) -gt 3 ]; then ups='"Connected to BR1"'; fi
         fi


         options="$options \"$wired\" $ups"

      fi
   fi

  done
  echo "$options" > /tmp/options
}

no_internet() {
  # We have NOT internet connection, but we have detected wired and/or wlan devices
  # so we will ask user what device will be use for connect to his/her internet router
  # once selected :

  # if wlan : scanning, show AP, prompt for AP password, try to connect and dhclient
  # if eth: try dhclient
  # if dhclient fails : ask user to enter IP, mask and default gw IP for the selected interface ( any ) 
  # 
  rm /tmp/inet_iface 2> /dev/null
  if [ ! $inet_iface ]; then
    dialog --colors --title "Librerouter Setup" --menu "Please select the interface you are using to connect to internet router (wan): " 25 60 55 --file /tmp/options 2> /tmp/inet_iface
    retval=$?
    if [ $retval == "1" ]; then
      main_menu
    fi
    inet_iface=$(cat /tmp/inet_iface)
    if [[ $inet_iface =~ "eth0" ]]; then inet_iface="eth0"; fi
    if [[ $inet_iface =~ "eth1" ]]; then inet_iface="eth1"; fi
    if [[ $inet_iface =~ "eth2" ]]; then inet_iface="eth2"; fi
    if [[ $inet_iface =~ "eth3" ]]; then inet_iface="eth3"; fi
    if [[ $inet_iface =~ "eth4" ]]; then inet_iface="eth4"; fi
    if [[ $inet_iface =~ "eth5" ]]; then inet_iface="eth5"; fi
    if [[ $inet_iface =~ "eth6" ]]; then inet_iface="eth6"; fi
    if [[ $inet_iface =~ "eth7" ]]; then inet_iface="eth7"; fi
    if [[ $inet_iface =~ "wlan0" ]]; then inet_iface="wlan0"; fi
    if [[ $inet_iface =~ "wlan1" ]]; then inet_iface="wlan1"; fi
    if [[ $inet_iface =~ "wlan2" ]]; then inet_iface="wlan2"; fi
    if [[ $inet_iface =~ "wlan3" ]]; then inet_iface="wlan3"; fi
    if [[ $inet_iface =~ "wlan4" ]]; then inet_iface="wlan4"; fi
  fi


   # In some cases the selected interface may be in use, but the user want to change it
   # Then prompt user to confirm to change this in use interface and stop services on it, and then re-scan

   # Is already in use interface $inet_iface ?
  inuse=""
  if [[ $(ps auxwwww | grep hostapd) =~ $inet_iface ]]; then inuse="hostapd"; fi
  if [[ $(ps auxwwww | grep wpa_supplicant) =~ $inet_iface ]]; then inuse="wpa"; fi
  packetcount1=$(ifconfig $inet_iface | grep "RX pack")
  sleep 2;
  packetcount2=$(ifconfig $inet_iface | grep "RX pack")
  if [ "$packetcount1" == "$packetcount2" ]; then echo > /dev/null; else inuse="connected"; fi

  if [ ${#inuse} -gt 1 ]; then
     dialog --colors --defaultno --title "Librerouter Setup" --yesno  "The interface $inet_iface you have chosen is already in use by $inuse.\nAre you sure you want to re-configure it ?" 9 40
     retval=$?
     if [ $retval == "1" ]; then
       main_menu
     fi
     if [ $retval == "0" ]; then
         if [[ $inuse =~ "hostapd" ]]; then 
             killall -9 hostapd 1> /dev/null 2> /dev/null
             ifconfig $inet_iface down > /dev/null 2> /dev/null
             dialog --colors --defaultno --title "Librerouter Setup" --infobox "Stoping older Access Point service" 0 0
             sleep 5
         fi
         if [[ $inuse =~ "wpa" ]]; then 
             killall -9 wpa_supplicant 1> /dev/null 2> /dev/null
             ifconfig $inet_iface 0.0.0.0
             ifconfig $inet_iface down > /dev/null 2> /dev/null
             dialog --colors --defaultno --title "Librerouter Setup" --infobox "Stoping older connection to Access Point" 0 0
             sleep 5
         fi

     fi
  fi



  if [[ $inet_iface =~ "wlan" ]]; then
    # Here the user have selected WAN interface
    # We need to offer available ESSID and prompt for AP password
    # Let's go to fetch all AP's ESSID  in the area and quality of each one
    ifconfig $inet_iface up > /dev/null
    scanning=$(iwlist $inet_iface scanning 2> /dev/null)
    #essids=$(
    echo "$scanning" | grep ESSID | cut -d : -f 2 | cut -d '"' -f 2 > /tmp/essids
    #qualities=$(
    echo "$scanning" | grep Quality | cut -d = -f 2 | cut -d /  -f 1 > /tmp/qualities
    essids=$(cat /tmp/essids)
    qualities=$(cat /tmp/qualities)
    
    local IFS=$'\n'
    o=0
    for q in $qualities; do
      quality[$o]="$q"
      if [ ${quality[$o]} == "" ] || [[ "${quality[$o]}" =~ "i" ]] || [[ "${quality[$o]}" =~ " " ]] || [ ${#q} -gt 2 ]; then
         quality[$o]="-"
      fi
      if [ ${#q} -gt 2 ]; then
         quality[$o]="' '"
      fi
      o=$((o+1))
    done

    o=0
    options=""
    for essid in $essids; do
      #essid=$(echo $essid | sed -e "s/!/\\\!/g")
      #essid=$(echo $essid | sed -e "s/ /\\\ /g")
      options="$options \"$essid\" ${quality[$o]}"
      o=$((o + 1))
    done
  
    
   local IFS=$' \t\n'

   # In the event no AP are detected in the area
   while [ $o -lt 1 ]; do
     dialog --colors --title "Librerouter Setup" --yes-label "Re-scan" --no-label "Cancel" --yesno "No any Access Point have been detected" 0 0
     retval=$?
     if [ $retval == "3" ]; then
      check_ifaces
      no_internet
     fi
     if [ $retval == "1" ]; then
      main_menu
     fi

   done


# joaquin
   echo "dialog --colors --title \"Librerouter Setup - $inet_iface\" --extra-button --extra-label \"Re-scan\" --menu \"Please select your Access Point : \" 25 40 55 $options" > /tmp/select_ap
    chmod u+x /tmp/select_ap > /dev/null
    /tmp/select_ap 2> /tmp/essid
    retval=$?
    if [ $retval == "3" ]; then
      check_ifaces
      no_internet
    fi
    if [ $retval == "1" ]; then
      rm /tmp/inet_iface
      main_menu
    fi
    essid=$(cat /tmp/essid)

    while [ ${#wifi_pass} -lt 8 ]; do
    
      dialog --colors --title "Librerouter Setup" --extra-button --extra-label "Back" --form "Enter your $essid WIFI Access Point password, minimun 8 characters" 0 0 1 "WIFI Password:" 1 2 "" 1 20 20 20 2> /tmp/wifipass
      retval=$?
      if [ $retval == "1" ]; then
        main_menu
      fi
      if [ $retval == "3" ]; then
        check_ifaces
        no_internet
      fi
      wifi_pass=$(cat /tmp/wifipass)
    done


    mkdir /etc/wpa 2> /dev/null
    echo -e "ctrl_interface=/var/run/wpa_supplicant\nctrl_interface_group=root\n" > /etc/wpa/_supplicant.conf
    wpa_passphrase "$essid" "$wifi_pass" >> /etc/wpa/_supplicant.conf

    # Conectamos al AP 
    while [[ $(ps auxwww) =~ "wpa_supplicant" ]]; do
       killall wpa_supplicant
       sleep 1
    done
    rm /var/run/wpa_supplicant/$inet_iface 1> /dev/null 2> /dev/null
    ifconfig $inet_iface 0.0.0.0
    ifconfig $inet_iface down
    rm /tmp/wpasupp_status 2> /dev/null
    sleep 1
    wpa_supplicant -B -c/etc/wpa/_supplicant.conf -Dwext -i$inet_iface -ddd 1> /dev/null 2> /dev/null 
    dialog --colors --title "Librerouter Setup" --infobox "Trying to connect to AP $essid" 7 45
    sleep 15
    # Now check wpa_supplicanat has success
    wpa_success=$(iwconfig $inet_iface | grep "Access Point:")
    if [[ "$wpa_success" =~ "Not-Associated" ]]; then
       # Connection failed to AP, go again to prompt for AP key
       dialog --colors --title "Librerouter Setup" --msgbox "\Zb\Z1Can NOT connect to $essid AP. Please check your ESSID and password and try again.\ZB\Zn" 7 45
       rm /tmp/wifipass 2> /dev/null
       wifi_pass=""
       ifconfig $inet_iface 0.0.0.0
       ifconfig $inet_iface down
       killall wpa_supplicant
       no_internet
    fi
  fi




}




try_dhcp() {
    dialog --title "Librerouter Setup"  --infobox "Trying DHCP for interface $inet_iface ... Please wait" 0 0
    dhclient $inet_iface  1> /dev/null 2> /dev/null &
    sleep 10
    killall dhclient 1> /dev/null 2> /dev/null
    ifaceip=$(ifconfig $inet_iface | grep "inet addr" | cut -d : -f  2 | cut -d \  -f1)
    if [[ "$ifaceip" =~ "." ]]; then
        dhclient $inet_iface &
        dialog --colors --title "Librerouter Setup" --msgbox "DHCP for interface $inet_iface got ip address $ifaceip" 0 0
    else 
        set_ipmaskgw
    fi
}

set_ipmaskgw() {
    local IFS=$'\n'
    dialog --colors --title "Librerouter Setup" --extra-button --extra-label "Back" --form "$err\n\ZnEnter your network params for connect to internet router" 0 0 3 "IP:" 1 2 "$iface_ip" 1 20 20 20 "Mask:" 2 2 "255.255.255.0" 2 20 20 20 "Gateway:" 3 2 "$gw" 3 20 20 20 2> /tmp/network_ipmaskgw
    retval=$?
    if [ $retval == "3" ]; then
      check_ifaces
      no_internet
    fi
    if [ $retval == "1" ]; then
      main_menu
    fi
    ipmaskgw=$(cat /tmp/network_ipmaskgw)
    thiscounter=0
    for lines in $ipmaskgw; do
      if [ $thiscounter = "0" ]; then 
        iface_ip="$lines"
      fi
      if [ $thiscounter = "1" ]; then 
        mask="$lines"
      fi
      if [ $thiscounter = "2" ]; then 
        gw="$lines"
      fi
      ((thiscounter++))
    done
#    netcalc $iface_ip $mask
#    bcastcalc $iface_ip $mask
    check_gw $gw $mask
}


netcalc(){

    local IFS='.' ip i
    local -a oct msk
        
    read -ra oct <<<"$1"
    read -ra msk <<<"$2"

    for i in ${!oct[@]}; do
        ip+=( "$(( oct[i] & msk[i] ))" )
    done
    
    net="${ip[*]}"
    read -ra oct <<<"${ip[*]}"
    dec_net=$((256*256*256*oct[0]+256*256*oct[1]+256*oct[2]+oct[3]))
}

bcastcalc(){

    local IFS='.' ip i
    local -a oct msk
	
    read -ra oct <<<"$1"
    read -ra msk <<<"$2"

    for i in ${!oct[@]}; do
        ip+=( "$(( oct[i] + ( 255 - ( oct[i] | msk[i] ) ) ))" )
    done

    bcast="${ip[*]}"
    read -ra oct <<<"${ip[*]}"
    dec_bcast=$((256*256*256*oct[0]+256*256*oct[1]+256*oct[2]+oct[3]))
}

check_gw() {
    # Check if gw address is valid
    dhcp=0
    local IFS='.' ip i
    local -a oct msk
    read -ra oct <<<"$1"
    dec_gw=$((256*256*256*oct[0]+256*256*oct[1]+256*oct[2]+oct[3]))
    # echo "Valores GW:$dec_gw NET:$dec_net BC:$dec_bcast"
    if [ ! $(expr "$gw" : "^[0-9.]*$") -gt 0 ];then
        err="\Z1\ZbError: Gateway $gw Invalid value.\ZB\Zn"
        set_ipmaskgw
    fi
    if [ ! $(expr "$iface_ip" : "^[0-9.]*$") -gt 0 ];then
        err="\Z1\ZbError: IP $iface_ip Invalid value.\ZB\Zn"
        set_ipmaskgw
    fi
    if [ ! $(expr "$mask" : "^[0-9.]*$") -gt 0 ];then
        err="\Z1\ZbError: Mask $mask Invalid value.\ZB\Zn"
        set_ipmaskgw
    fi

    netcalc $iface_ip $mask
    bcastcalc $iface_ip $mask

    if [ $dec_gw -lt $dec_net ] || [ $dec_bcast -lt $dec_gw ]; then
        err="\Z1\ZbError: Gateway $gw doesn't match Mask $mask GW:$dec_gw NET:$dec_net BC:$dec_bcast\ZB\Zn"
        set_ipmaskgw
    else
        ifconfig $inet_iface $iface_ip $mask 2> /dev/null
        route add default gw $gw 2> /dev/null
    fi
}


save_network() {
  if [[ $inet_iface =~ "eth" ]]; then
    if [ $dhcp == "0" ]; then
       cat << EOT >  /tmp/EXT_interfaces
        auto $inet_iface
        iface $inet_iface inet static\n
            address $iface_ip
            netmask $mask
            network $net

EOT
    else
       cat << EOT >  /tmp/EXT_interfaces
        auto $inet_iface
        iface $inet_iface inet dhcp\n
EOT
    fi
  fi

  if [[ $inet_iface =~ "wlan" ]]; then
     cat <<EOT  | grep -v EOT> /etc/init.d/start_wifi_client
#!/bin/sh
### BEGIN INIT INFO
# Provides: librerouter_wifi_client
# Required-Start: $syslog
# Required-Stop: $syslog
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: wifi_client
# Description:
#
### END INIT INFO

# Start WIFI internet connection as client of AP

    while [[ \$(ps auxwww) =~ "wpa_supplicant" ]]; do
       killall wpa_supplicant
       sleep 1
    done
    wpa_supplicant -B -c/etc/wpa/_supplicant.conf -Dwext -i$inet_iface
  
EOT

      chmod u+x /etc/init.d/start_wifi_client
      update-rc.d start_wifi_client defaults
  fi
  excluded_if=$inet_iface
  cp /etc/network/interfaces /etc/network/interfaces.back
  cat /tmp/LO_interfaces > /etc/network/interfaces
  cat /tmp/EXT_interfaces >> /etc/network/interfaces
  cat /tmp/INT_interfaces >> /etc/network/interfaces
  
}


config_hostapd() {
    # Check AP capabilities
    iw list | grep "* AP" | grep -v grep > /tmp/ap_cap
    AP_cap=$(cat /tmp/ap_cap)
    if [ ${#AP_cap} -lt 5 ]; then
       lan_iface=""
       dialog --colors --defaultno --title "Librerouter Setup" --msgbox "This WLAN device does NOT support AP mode" 7 40
       retval=$?
       if [ $retval == "0" ]; then
          main_menu
          #lan_config
       fi
       if [ $retval == "1" ]; then
          main_menu
       fi
    fi

    wpa=1
    wpa2=1
    wep=0
    # generates random ESSID
    essid=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-12})
    #echo "ESSID: $essid"
    # generates random plain key
    key=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-13})
    # echo "KEY: $key"
dialog --colors --defaultno --title "Librerouter Setup" --msgbox "\ZbIMPORTANT\ZB\n\nWrite your Access Point values:\n\nESSID: \Zb$essid\ZB\nKEY: \Zb$key\ZB\n\nYou will need it to configure your WIFI clients" 17 40 
    echo "interface=$lan_iface" > hostapd.conf
    chmod go-rwx hostapd.conf
    echo "#bridge=br1" >> hostapd.conf
    echo "logger_syslog=-1" >> hostapd.conf
    echo "logger_syslog_level=2" >> hostapd.conf
    echo "logger_stdout=0" >> hostapd.conf
    echo "logger_stdout_level=2" >> hostapd.conf
    echo "ctrl_interface=/var/run/hostapd.$iname" >> hostapd.conf
    echo "ctrl_interface_group=0" >> hostapd.conf
    echo "ssid=$essid" >> hostapd.conf
    echo "rsn_pairwise=CCMP" >> hostapd.conf

    if [ $wep = "1" ]; then
      echo "wep_key0=\"$key\"" >> hostapd.conf
    else
      echo "wpa=$wpa2$wpa" >> hostapd.conf
      echo "wpa_passphrase=$key" >> hostapd.conf
    fi
    cat << EOT >>  hostapd.conf
hw_mode=g
channel=1
beacon_int=100
dtim_period=2
max_num_sta=255
rts_threshold=2347
fragm_threshold=2346

macaddr_acl=0
# for further mac filtering once we know the hardware address of clients allowed ( from dhcpd.conf if configured by mac )
#accept_mac_file=/etc/hostapd.accept
#deny_mac_file=/etc/hostapd.deny

auth_algs=3
ignore_broadcast_ssid=0
wmm_enabled=1
# Low priority / AC_BK = background
wmm_ac_bk_cwmin=4
wmm_ac_bk_cwmax=10
wmm_ac_bk_aifs=7
wmm_ac_bk_txop_limit=0
wmm_ac_bk_acm=0
# Note: for IEEE 802.11b mode: cWmin=5 cWmax=10
#
# Normal priority / AC_BE = best effort
wmm_ac_be_aifs=3
wmm_ac_be_cwmin=4
wmm_ac_be_cwmax=10
wmm_ac_be_txop_limit=0
wmm_ac_be_acm=0
wmm_ac_vi_aifs=2
wmm_ac_vi_cwmin=3
wmm_ac_vi_cwmax=4
wmm_ac_vi_txop_limit=94
wmm_ac_vi_acm=0
wmm_ac_vo_aifs=2
wmm_ac_vo_cwmin=2
wmm_ac_vo_cwmax=3
wmm_ac_vo_txop_limit=47
wmm_ac_vo_acm=0
eapol_key_index_workaround=0
eap_server=0
device_name=Librerouter AP
friendly_name=Librerouter Access Point
EOT
    # cat hostapd.conf.base >> hostapd.conf
    # Update /etc/init.d/hostpad file
    updatehostpad=$(sed -e "s/DAEMON_CONF=/DAEMON_CONF=\/etc\/hostapd.$lan_iface.conf/g" /etc/init.d/hostapd > /etc/init.d/hostapd.tmp)
    mv /etc/init.d/hostapd.tmp /etc/init.d/hostapd
    # start AP daemon on interface
    mv hostapd.conf /etc/hostapd.$lan_iface.conf
    killall -9 hostapd 1> /dev/null 2> /dev/null
    ifconfig $inet_iface down > /dev/null 2> /dev/null
    # dialog --colors --defaultno --title "Librerouter Setup" --infobox "Stoping older Access Point" 7 45
    sleep 5
    rfkill unblock all
    hostapd /etc/hostapd.$lan_iface.conf  1> /dev/null 2> /dev/null & 
    chmod u+x /etc/init.d/hostapd
    update-rc.d hostapd defaults
}


lan_config() {

  if [ ! $lan_iface ]; then
    dialog --colors --title "Librerouter Setup" --menu "Please select the interface for your internal (lan): " 25 40 55 --file /tmp/options 2> /tmp/lan_iface
    retval=$?
    if [ $retval == "1" ]; then
      main_menu
    fi
    lan_iface=$(cat /tmp/lan_iface)
    if [[ "$lan_iface" =~ "eth0" ]]; then lan_iface="eth0"; fi
    if [[ "$lan_iface" =~ "eth1" ]]; then lan_iface="eth1"; fi
    if [[ "$lan_iface" =~ "eth2" ]]; then lan_iface="eth2"; fi
    if [[ "$lan_iface" =~ "eth3" ]]; then lan_iface="eth3"; fi
    if [[ "$lan_iface" =~ "eth4" ]]; then lan_iface="eth4"; fi
    if [[ "$lan_iface" =~ "eth5" ]]; then lan_iface="eth5"; fi
    if [[ "$lan_iface" =~ "eth6" ]]; then lan_iface="eth6"; fi
    if [[ "$lan_iface" =~ "eth7" ]]; then lan_iface="eth7"; fi
    if [[ "$lan_iface" =~ "wlan0" ]]; then lan_iface="wlan0"; fi
    if [[ "$lan_iface" =~ "wlan1" ]]; then lan_iface="wlan1"; fi
    if [[ "$lan_iface" =~ "wlan2" ]]; then lan_iface="wlan2"; fi
    if [[ "$lan_iface" =~ "wlan3" ]]; then lan_iface="wlan3"; fi
    if [[ "$lan_iface" =~ "wlan4" ]]; then lan_iface="wlan4"; fi
  fi
  inuse=""
  if [[ $(ps auxwwww | grep hostapd) =~ $lan_iface ]]; then inuse="hostapd"; fi
  packetcount1=$(ifconfig $lan_iface | grep "RX pack")
  sleep 2;
  packetcount2=$(ifconfig $lan_iface | grep "RX pack")
  if [ "$packetcount1" == "$packetcount2" ]; then echo > /dev/null; else inuse="connected"; fi
  if [ ${#inuse} -gt 1 ]; then
     dialog --colors --defaultno --title "Librerouter Setup" --yesno  "The interface $lan_iface you have chosen is already in use by $inuse.\nAre you sure you want to re-configure it ?" 9 40
     retval=$?
     if [ $retval == "1" ]; then
         main_menu
     fi
     if [ $retval == "0" ]; then
         if [[ $inuse =~ "hostapd" ]]; then
             killall -9 hostapd 1> /dev/null 2> /dev/null
             ifconfig $lan_iface down > /dev/null 2> /dev/null
             dialog --colors --defaultno --title "Librerouter Setup" --infobox "Stoping older Access Point" 7 45 
             sleep 5
         fi
      fi
  fi

  if [[ $lan_iface =~ "wlan" ]]; then
    config_hostapd
  fi
  # Remove all old entries in /etc/network/interfaces

  # Add new interface for lan in /etc/network/interfaces
  INT_INTERFACE="$lan_iface"
  cat << EOT >  /tmp/INT_interfaces

        #Internal network interface
        auto $INT_INTERFACE
        #allow-hotplug $INT_INTERFACE
        iface $INT_INTERFACE inet static
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

        #Kibana
        auto $INT_INTERFACE:7
        #allow-hotplug $INT_INTERFACE:7
        iface $INT_INTERFACE:7 inet static
            address 10.0.0.239
            netmask 255.255.255.0

        #Snorby
        auto $INT_INTERFACE:8
        #allow-hotplug $INT_INTERFACE:8
        iface $INT_INTERFACE:8 inet static
            address 10.0.0.12
            netmask 255.255.255.0

        #squidguard
        auto $INT_INTERFACE:9
        #allow-hotplug $INT_INTERFACE:9
        iface $INT_INTERFACE:9 inet static
            address 10.0.0.246
            netmask 255.255.255.0

        #gitlab
        auto $INT_INTERFACE:10
        #allow-hotplug $INT_INTERFACE:10
        iface $INT_INTERFACE:10 inet static
            address 10.0.0.247
            netmask 255.255.255.0

        #trac
        auto $INT_INTERFACE:11
        #allow-hotplug $INT_INTERFACE:11
        iface $INT_INTERFACE:11 inet static
            address 10.0.0.248
            netmask 255.255.255.0

        #redmine
        auto $INT_INTERFACE:12
        #allow-hotplug $INT_INTERFACE:12
        iface $INT_INTERFACE:12 inet static
            address 10.0.0.249
            netmask 255.255.255.0

        #Webmin
        auto $INT_INTERFACE:13
        #allow-hotplug $INT_INTERFACE:13
        iface $INT_INTERFACE:13 inet static
            address 10.0.0.244
            netmask 255.255.255.0

        #Roundcube
        auto $INT_INTERFACE:14
        #allow-hotplug $INT_INTERFACE:14
        iface $INT_INTERFACE:14 inet static
            address 10.0.0.243
            netmask 255.255.255.0

        #Postfix
        auto $INT_INTERFACE:15
        #allow-hotplug $INT_INTERFACE:15
        iface $INT_INTERFACE:15 inet static
            address 10.0.0.242
            netmask 255.255.255.0

        #Sogo
        auto $INT_INTERFACE:16
        #allow-hotplug $INT_INTERFACE:16
        iface $INT_INTERFACE:16 inet static
            address 10.0.0.241
            netmask 255.255.255.0

        #Glype
        auto $INT_INTERFACE:17
        #allow-hotplug $INT_INTERFACE:17
        iface $INT_INTERFACE:17 inet static
            address 10.0.0.240
            netmask 255.255.255.0

        #WAF-FLE
        auto $INT_INTERFACE:18
        #allow-hotplug $INT_INTERFACE:18
        iface $INT_INTERFACE:18 inet static
            address 10.0.0.238
            netmask 255.255.255.0

EOT
  # Reconfigure in the air without reboot


}

update_disk_pass() {
  # First of all we need to know the last used LUKS slot, old password and LUKS partition
  # update_def()
  echo
}



new_install() {
    # This is a new install
    start=1
    errmsg=""
    dialog --colors --title "Librerouter Setup"  --infobox "Waiting for Tahoe and Onion comes ready. Be patient, this can take up to 5 minutes" 0 0
    /etc/init.d/start_tahoe 1> /dev/null 2> /dev/null
    while [ ${#errmsg} -gt 0 ] || [ $start == "1" ]; do
               textmsg="Use a new name for your \ZbALIAS\ZB like \Z4Peter.Pan5\Zn\nUse enough strong \ZbPASSWORD\ZB \Z1minimum 8 digits long\Zn and write down in a safe place.\n\Z1$errmsg\Zn\n"
               dialog --colors --title "Librerouter Setup" --form "$textmsg" 0 0 3 "Enter your alias:" 1 2 "$myalias"  1 20 20 20 "Passwod:" 2 2 "" 2 20 20 20 "Repeat Password:" 3 2 "" 3 20 20 20 2> /tmp/inputbox.tmp
               retval=$?
               if [ $retval == "1" ]; then
                   main_menu
               fi
               credentials=$(cat /tmp/inputbox.tmp)
               rm /tmp/inputbox.tmp
               errmsg=""
               thiscounter=0
               for lines in $credentials; do
                  #while IFS= read -r lines; do
                  if [ $thiscounter = "0" ]; then 
                      myalias="$lines"
                  fi
                  if [ $thiscounter = "1" ]; then 
                      myfirstpass="$lines"
                  fi
                  if [ $thiscounter = "2" ]; then 
                      mysecondpass="$lines"
                  fi
                  ((thiscounter++));    
               done
               strleng=${#myalias}
               if [[ $strleng -lt 8 ]]; then
                   errmsg="\Zb$myalias ${#myalias} Must be at least 8 characters long\ZB"
               fi
               if [ -z "${myfirstpass##*" "*}" ]; then
                   errmsg="\ZbSpaces are not allowed\ZB";
               fi
               strleng=${#myfirstpass}
               if [[ $strleng -lt 8 ]]; then
                   errmsg="\Zb$myfirstpass ${#myalias} Must be at least 8 characters long\ZB"
               fi
               if [ $myfirstpass != $mysecondpass ]; then
                   errmsg="\ZbPlease repeat same password\ZB"
               fi
               start=0
    done
    # creates PEM 
    rm /tmp/ssh_keys*
    ssh-keygen -N $myfirstpass -f /tmp/ssh_keys 1> /dev/null 2> /dev/null
    openssl rsa  -passin pass:$myfirstpass -outform PEM  -in /tmp/ssh_keys -pubout > /tmp/rsa.pem.pub
    frase=$(cat /usr/node_1/private/accounts | head -n 1)
    echo $frase | openssl rsautl -encrypt -pubin -inkey /tmp/rsa.pem.pub  -ssl > /tmp/$myalias
    /home/tahoe-lafs/venv/bin/tahoe cp  -u http://127.0.0.1:9456 /tmp/$myalias public_node:
    # mv /tmp/$myalias /var/public_node/$myalias
    thiscounter=0
    output=''
    while [ $thiscounter -lt 30 ]; do
       ofuscated=$ofuscated${myalias:$thiscounter:1}$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-4})
       ((thiscounter++));
    done
    /home/tahoe-lafs/venv/bin/tahoe cp  -u http://127.0.0.1:9456 /tmp/ssh_keys public_node:.keys/$ofuscated
    # cp /tmp/ssh_keys  /var/public_node/.keys/$ofuscated
    update_root_pass
    update_disk_pass
    update_def_pass
    echo $myalias > /root/alias
    main_menu
}

new_pass() {
    myalias=$(cat /root/alias)
    if [ ${#myalias} -lt 4 ]; then
        new_install
        main_menu
    fi
    start=1
    errmsg=""
    while [ ${#errmsg} -gt 0 ] || [ $start == "1" ]; do
               textmsg="Use enough strong \ZbPASSWORD\ZB \Z1minimum 8 digits long\Zn and write down in a safe place.\n\Z1$errmsg\Zn\n"
               dialog --colors --title "Librerouter Setup" --form "$textmsg" 0 0 2 "Passwod:" 1 2 "" 1 20 20 20 "Repeat Password:" 2 2 "" 2 20 20 20 2> /tmp/inputbox.tmp
               retval=$?
               if [ $retval == "1" ]; then
                   main_menu
               fi
               credentials=$(cat /tmp/inputbox.tmp)
               rm /tmp/inputbox.tmp
               errmsg=""
               thiscounter=0
               for lines in $credentials; do
                  #while IFS= read -r lines; do
                  if [ $thiscounter = "0" ]; then 
                      myfirstpass="$lines"
                  fi
                  if [ $thiscounter = "1" ]; then 
                      mysecondpass="$lines"
                  fi
                  ((thiscounter++));    
               done
               if [ -z "${myfirstpass##*" "*}" ]; then
                   errmsg="Spaces are not allowed";
               fi
               strleng=${#myfirstpass}
               if [[ $strleng -lt 8 ]]; then
                   errmsg="$myfirstpass ${#myalias} Must be at least 8 characters long"
               fi
               if [ $myfirstpass != $mysecondpass ]; then
                   errmsg="Please repeat same password"
               fi
               start=0
    done
    # creates PEM 
    rm /tmp/ssh_keys* 2> /dev/null
    ssh-keygen -N $myfirstpass -f /tmp/ssh_keys 1> /dev/null 2> /dev/null
    openssl rsa  -passin pass:$myfirstpass -outform PEM  -in /tmp/ssh_keys -pubout > /tmp/rsa.pem.pub
    frase=$(cat /usr/node_1/private/accounts | head -n 1)
    echo $frase | openssl rsautl -encrypt -pubin -inkey /tmp/rsa.pem.pub  -ssl > /tmp/$myalias
    /home/tahoe-lafs/venv/bin/tahoe cp  -u http://127.0.0.1:9456 /tmp/$myalias public_node:
    # mv /tmp/$myalias /var/public_node/$myalias
    thiscounter=0
    output=''
    while [ $thiscounter -lt 30 ]; do
        ofuscated=$ofuscated${myalias:$thiscounter:1}$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-4})
        ((thiscounter++));
    done
    /home/tahoe-lafs/venv/bin/tahoe cp  -u http://127.0.0.1:9456 /tmp/ssh_keys public_node:.keys/$ofuscated
    # cp /tmp/ssh_keys  /var/public_node/.keys/$ofuscated
    update_root_pass
    update_disk_pass
    update_def_pass
    main_menu
}


main_menu() {
    rm /tmp/inet_iface 2> /dev/null
    rm /tmp/essid 2> /dev/null
    rm /tmp/alias 2> /dev/null
    rm /tmp/wifipass 2> /dev/null
    inet_iface=""
    lan_iface=""
    alias=""
    wifi_pass=""

    dialog --colors --title "Librerouter Setup" --cancel-label Exit --menu "" 0 0 5 1 "Configure my internet conection " 2 "Configure my Secure internal new area " 3 "Recover from backup" 4 "Change my password" 5 "Configure services"   2> /tmp/main_menu
    retval=$?
    if [ $retval == "1" ]; then
      exit;
    fi
    main_option=$(cat /tmp/main_menu)

    # Config WLAN INTERFACE
    if [ $main_option == "1" ]; then
      check_internet
      if [ $internet == "1" ]; then
        dialog --colors --defaultno --title "Librerouter Setup" --yesno  "Your internet is already working.\nDo you want to re-configure it ?" 7 40  2> /tmp/reconf_internet
        retval=$?
        if [ $retval == "1" ]; then
           main_menu
        fi
        if [ $retval == "0" ]; then
           check_ifaces
           no_internet
           try_dhcp
           check_internet
           if [ $internet == "0" ]; then
             set_ipmaskgw
             check_internet
             if [ $internet == "0" ]; then
                dialog --title "Librerouter Setup"  --infobox "Something gone wrong. May be you entered wrong password for your WIFI, or may be you have not plugged the ethernet wire in the right slot" 0 0
             exit
             else
                save_network
             fi
           else 
                save_network
           fi
        fi
      
      else

           check_ifaces
           no_internet
           try_dhcp
           check_internet
           if [ $internet == "0" ]; then
             set_ipmaskgw
             check_internet
             if [ $internet == "0" ]; then
                dialog --title "Librerouter Setup"  --infobox "Something gone wrong. May be you entered wrong password for your WIFI, or may be you have not plugged the ethernet wire in the right slot" 0 0
             exit
             else
                save_network
             fi
           fi
      fi
      main_menu
    fi


    # Config LAN INTERFACE
    if [ $main_option == "2" ]; then
        # Much more complicated as we need to setup the LAN and put there all subinterface and rules
            check_ifaces
            lan_config
            main_menu
    fi


    # Prompt for Tahoe recover from backup
    if [ $main_option == "3" ]; then
               dialog --title "Librerouter Setup"  --infobox "Waiting for Tahoe and Onion comes ready.\nBe patient, this can take up to 5 minutes" 0 0
               # Se supone que thaoe debio ser iniciado ya en otro lado  Joaquin no iniciar de nuevo /etc/init.d/start_tahoe 1> /dev/null 2> /dev/null
               # collect aliases
               options=""
               aliasesdb=$(dir /var/public_node -l  | grep ^- | cut -c 41-74)
               concat=" - "
               for names in $aliasesdb; do
                   ## names=${names,,} translate to lower case
                   # if [[ $names == *$alias_lc* ]]; then
                       if [ ${#options} -lt 1 ]; then
                          options=$names
                       else 
                          options=$options$concat$names
                       fi
                   # fi
               done
               options="$options $concat"
               rm -rf /tmp/alias
               while [ ! $alias ]; do
                 dialog --colors --menu "Please select you ALIAS from the list: " 25 0 45 $options 2> /tmp/alias
                 retval=$?
                 if [ $retval == "1" ]; then
                   main_menu
                 fi
                 alias=$(cat /tmp/alias)
                 rm -rf /tmp/alias 2> /dev/null
               done

               textmsg="Enter your backup password for $alias:"
               dialog --colors --form "$textmsg" 0 0 1 "Passwod:" 1 2 "" 1 20 20 20 2> /tmp/inputbox.tmp
               retval=$?
               if [ $retval == "1" ]; then
                   main_menu
               fi
               passwd=$(cat /tmp/inputbox.tmp)
               rm /tmp/inputbox.tmp
               deo='';
               thiscounter=0
               com="????";
               while [ $thiscounter -lt 30 ]; do
                   deo=$deo${alias:$thiscounter:1}$com
                   ((thiscounter++));
               done
               ############# deo=$deo?
               # if cpu load used by tahoe instances are higher than 10% all operations through tahoe services are too slow
               # we would need to wait until there enough resources to start tasks on tahoe services
               # usually on idle status ( only offered space ) CPU load must be < 2%
               # This is also notciable on tcpdump -n port 9001 or port 443 , tracking the Tor entry point IP

               # tahoe_node_1_load=99
               # while [ $tahoe_node_1_load -gt 10 ]; do
               #    tahoe_node_1_load=$(ps auxwwww | grep tahoe | grep -v grep | grep node_1 | cut -c 15-19 | cut -d \. -f 1)
               #    # echo -n -e "\rTahoe node_1 load is $tahoe_node_1_load ... please wait $moving_char"
               #    tahoe_node_1_load2=$(( 99-$tahoe_node_1_load ))
               #    echo "$tahoe_node_1_load2"  | dialog --title "Librerouter Setup " --gauge "Preparing for recover ..." 10 60 0
               #    sleep 5
               #    # moving
               # done

               tahoe_public_node_load=99
               while [ $tahoe_public_node_load -gt 10 ]; do
                   tahoe_public_node_load=$(ps auxwwww | grep tahoe | grep -v grep | grep public_node  | cut -c 15-19 | cut -d \. -f 1)
                   echo -n -e "\rTahoe public_node load is $tahoe_public_node_load ... please wait $moving_char"
                   tahoe_public_node_load2=$(( 99-$tahoe_public_node_load ))
                   echo "$tahoe_public_node_load2"  | dialog --title "Librerouter Setup " --gauge "Preparing for recover ..." 10 60 0
                   sleep 5
                   # moving
               done

               pb_point=$(echo $passwd | openssl rsautl -decrypt -inkey /var/public_node/.keys/$deo -in /var/public_node/$alias -passin stdin)


               # reconfigure node_1 mapping point
               # we need no just to restore my files, also my storage that contents file chunks from others to rebuild the full lost node
               # and avoid damages in the grid performance and realibility
               # we need to check there not existing node with same node_1 directory mounted in other box

               if [[ ${#pb_point} -gt 25 ]]; then
                   # if running, stop private node
                   /home/tahoe-lafs/venv/bin/tahoe stop /usr/node_1 > /dev/nul

                   echo $pb_point | cut -d \  -f 1,2 > /root/.tahoe/node_1  # save credentials for node_1 restoration
                   echo $pb_point > /usr/node_1/private/accounts            # save cap for node_1 restoration
                   echo "public_node: URI:DIR2:rjxappkitglshqppy6mzo3qori:nqvfdvuzpfbldd7zonjfjazzjcwomriak3ixinvsfrgua35y4qzq" > /root/.tahoe/private/aliases
                   pb_point2=$(echo "$pb_point" | cut -d \   -f 3)
                   echo "node_1: $pb_point2" >> /root/.tahoe/private/aliases
                   # now we will able start to node_1 ,mount /var/node_1 and first of all recover node_1.tar.gz for the full node_1 restoration
                   # including the shares 


                   /home/tahoe-lafs/venv/bin/tahoe start /usr/node_1

                   tahoe_node_1_load=99
                   while [ $tahoe_node_1_load -gt 10 ]; do
                       tahoe_node_1_load=$(ps auxwwww | grep tahoe | grep -v grep | grep node_1 | cut -c 15-19 | cut -d \. -f 1)
                       tahoe_node_1_load2=$(( 99-$tahoe_node_1_load ))
                       echo "$tahoe_node_1_load2"  | dialog --title "Librerouter Setup " --gauge "Preparing for recover ..." 10 60 0
                       sleep 5
                   done


                   # Check connected enough good nodes before to continue 

                  connnode_1=0
                  while [ $connnode_1 -lt 7 ]; do
                     connnode_1=$(curl http://127.0.0.1:3456/ 2> /dev/null| grep "Connected to tor" | wc -l)
                  done

                  # Now we know node_1 is ready, let's go to do paranoic check/repair on it

                  /home/tahoe-lafs/venv/bin/tahoe deep-check --repair -u http://127.0.0.1:3456 node_1:

                  # Check for available backup file

                  if [[ $(/home/tahoe-lafs/venv/bin/tahoe ls -l  -u http://127.0.0.1:3456 node_1:) =~ "sys.backup.tar.gz" ]]; then 
                      # Recover the backup file 
                      echo "Please wait. This will take over 30 minutes..."
                      /home/tahoe-lafs/venv/bin/tahoe cp -u http://127.0.0.1:3456 node_1:sys.backup.tar.gz /tmp/sys.backup.tar.gz &

                      # Mostramos progreso del download 
                      progress="00.00.00"
                      while [ ${#progress} -gt 0 ];do
                          progress=$(curl http://127.0.0.1:3456/status/ 2> /dev/null | grep "%</td>" | head -n 1 | cut -d \> -f 2 | cut -d \. -f 1)
                          echo "Downloading..."   ;echo "$progress" | dialog --title "Librerouter Backup restore" --gauge "Downloading ..." 10 60 0
                          if [[ $progress =~ "100" ]]; then
                              progress=""
                          fi
                          sleep 10
                      done

                      # Gracefully stop all Tahoe nodes before to extract files from backup
                      # ########/home/tahoe-lafs/venv/bin/tahoe stop /usr/node_1
                      # ########/home/tahoe-lafs/venv/bin/tahoe stop /usr/public_node

                      # Let's go to install the files from sys.backup.tar.gz 
                      # ############mv /tmp/sys.backup.tar.gz /.
                      # ############cd /
                      # ############tar xzf sys.backup.tar.gz
                  else
                      dialog --colors --title "Librerouter Setup" --msgbox  "There no any backup for this node." 7 40
                      main_menu
                  fi
               fi
    fi

    # change password for root, tahoe and disk encryption
    if [ $main_option == "4" ]; then
        new_pass
        main_menu
    fi

}

# This user interface will detect the enviroment and will chose a method based
# on this order : X no GTK, X with GTK , dialaog, none )

interface=0
excluded_if="ninguna"
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

alias=""
rm -rf /tmp/alias
rm -rf /tmp/inet_iface
dhcp=1
create_default_interfaces
wellcome
main_menu
exit

