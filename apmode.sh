#!/bin/bash

#
# This scripts aim to configure WLAN interface 
#

# ----------------------------------------------
# Configure WiFi Access Point
# ----------------------------------------------
configure_apd()
{
 # Configure WPA and/or WPA2 or WEP. For wep=1 , wpa and wpa2 MUST be 0
        wpa=0
        wpa2=1
        pke=0

        #if [ ! -e /usr/sbin/iw ] && [ ! -e /sbin/iw ]; then
        #       apt-get install -y --force-yes iw
        #fi

        echo "Checking for WLAN ..." | tee -a /var/libre_config.log

        AP_cap=$(iw list | grep "* AP" | grep -v grep)
        if [ "$AP_cap" = "" ]; then
                echo "This WLAN does NOT support AP mode"
                exit 1;
        fi

        if [ -e /sys/class/net/wlan* ]; then
                for filename in /sys/class/net/wlan*; do
                        iname=${filename##*/}
                        echo "INTERFACE: $iname"
                        # generates random ESSID
                        essid=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-12})
                        echo "ESSID: $essid"
                        # generates random plain key
                        key=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-13})
                        echo "KEY: $key"


                        echo "interface=$iname" > hostapd.conf
                        chmod go-rwx hostapd.conf
                        echo "#bridge=eth0" >> hostapd.conf
                        echo "logger_syslog=-1" >> hostapd.conf
                        echo "logger_syslog_level=2" >> hostapd.conf
                        echo "logger_stdout=0" >> hostapd.conf
                        echo "logger_stdout_level=2" >> hostapd.conf
                        echo "ctrl_interface=/var/run/hostapd.$iname" >> hostapd.conf
                        echo "ctrl_interface_group=0" >> hostapd.conf
                        echo "ssid=$essid" >> hostapd.conf
                        echo "rsn_pairwise=CCMP" >> hostapd.conf
                        echo "ap_isolate=1" >> hostapd.conf

                        if [ "$wep" = "1" ]; then
                                echo "wep_key0=\"$key\"" >> hostapd.conf
                        else
                                echo "wpa=$wpa2$wpa" >> hostapd.conf
                                echo "wpa_passphrase=$key" >> hostapd.conf
                        fi

                        cat << EOF >> hostapd.conf
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
EOF


                        # Update /etc/init.d/hostpad file
                        updatehostpad=$(sed -e "s/DAEMON_CONF=/DAEMON_CONF=\/etc\/hostapd.$iname.conf/g" /etc/init.d/hostapd > /etc/init.d/hostapd.tmp)
                        mv /etc/init.d/hostapd.tmp /etc/init.d/hostapd
                        # start AP daemon on interface
                        mv hostapd.conf /etc/hostapd.$iname.conf
                        rfkill unblock all
                        hostapd /etc/hostapd.$iname.conf &
                        chmod u+x /etc/init.d/hostapd
                done

        else
                echo "no existe"
        fi
}

configure_apd

