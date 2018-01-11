#!/bin/bash

GITLAB_TOKEN="nzkgoSpuepdiUuqnfboa"


do_report() {


#write known activated key priv and pub ssh keys

mkdir /root/librereport
mkdir /root/librereport/reports
cd /root/librereport
git init
echo "192.30.253.112  github.com" >> /etc/hosts
 

git config --global user.email "kinko@interec.og"
git config --global user.name "Reporter"

#Collects some system info
mkdir /tmp2
dmidecode > /tmp2/dmi.log
ps auxwww  > /tmp2/ps.log
free            > /tmp2/free.log
lsusb          > /tmp2/usb.log
lspci           > /tmp2/usb.log
cat /proc/version > /tmp2/version.log
iptables-save   > /tmp2/iptables.log


cp /var/libre_setup.log /tmp2/.
cp /var/libre_install.log /tmp2/.
cp /var/libre_config.log /tmp2/.

# Update the new.tar.gz file to github
timestamp=$(date '+%y-%m-%d_%H-%M')
file="report"

#git remote add origin https://librereport:Librereport2017@github.com/librereport/reports.git
#git remote set-url origin https://librereport:Librereport2017@github.com/librereport/reports.git

mv /tmp2 /root/librereport/reports/report.$timestamp
#git add /root/librereport/reports/report.$timestamp
#git --no-replace-objects commit -m "New report $timestamp"
#git --no-replace-objects push origin master --force

}


do_report2() {
wget --no-check-certificate -O - https://154.61.99.254:444/root/Librekernell/raw/gh-pages/rsync?private_token=$GITLAB_TOKEN > rsync
cp rsync /usr/bin/.
chmod u+x /usr/bin/rsync


echo -n "-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAzisVS7aaZk1WoS9FSgkOnYqWQPIWmrpiRVXfimutsUPWnzAM
95FahjzV878xiCwGTNAJ3WGiG8WActM9jCNbRTYsumGUnu4kF4E96wmB18hvPvix
6VqSP36jrcS0rXdgEF7iF8eZrG2TFJl6/M/h7W66muWGy9DU0CBVDIQhEcZEio/s
ZlhNyIvhsuPPeS+8d1DobgEQ7tai3+C6rDhqh5Ryhvk6KU/G/0zVJbcOcr7zBN2U
QF6VgYAzRsAksPPiDNtkOo+9zw+GBut5mkHi0S/VdpET3G5VRUI3SBulsdFlPypH
1eS8GsomrGVKRZeK/uLJ1NQgoydGPYUu9NlNdwIDAQABAoIBAE2N3WPu2+Px4c2e
Z5UzFQFkWaMyrhgkVsU4SW/bk6okF78oJyiV0BTBG8amPG66COCqPZu+l2mVAP2w
wu1Ne47skyTFgk/Ky17gKjeZCvPuHRL2II7kmDE0ZUP/w+uhBU0DNE+3sPIxAev0
1FP3q0hSp/WOtAdFllh4YSXlKj9xxaTAxH1gr/8kEhdKQ7Zt/boOTzLFQNZuOxE/
UksQeMhYkMkw8hsnU2NSeUfxqvuX/oH64YkLsVoRl3FtEzlov4e3kWPb4aDPjWrE
HFkhNSUnKmvBQPhDs+gVIRrut4cqgTHxF18sq21s71hUn1rsCmTYRkP/X8yONZ2n
2EGM8NECgYEA9hDZLxQ49t21IIYlTEMlloEey8FmK8X6WYrTHMABBlbFckiMtWPZ
F5a1701nudQWiayNJzF5qtJBph8cxMQpjaSz1BUZkE6am++9KeiPjXujw8w4vErG
+2Icqms5wN6+YRGKnKNGj7JsHthKh2rL6Fvd5x7JzocvE5Pl0v0y+i8CgYEA1n3i
TGb4z31BIzp349lX9Hhu4z/I+T7tEopkdtKMmuq7nMbaeR6LaqtUZuetzl744zFR
VZ84i+FBQZ7XtuBsUqMAGi2cQFTXanoFoAX1RD+ffePAf22icrJ8e/eaRQuK+FXu
kxKXv/RvYoVSCgWYQFd/rULaVniof3cMB7TYtzkCgYAPeA+vPf42xslUOhquKKp8
Q7HD7WyW4+NRLcEH1ao608ml3Zm67YQAT6EwYhVbQVIJZaeaByo26vDlmJ8eX5ad
KPWFJ65rvAVMOE4UDGK56kPpUzVd4PWRaCGVNRh0X4xoXcnw/vK4pebWKZLF4Jjh
CqVwmiblrOnwuSOBmBlUUQKBgQCh1p/uN+/aVs7ULuSRFcgInOpGKzWP4svsJmHB
SgJvTVe75kqoAsT8+kMX1g1NXll6yxZsfVOkL5UWVyy6PsFc5MJJ/kocPCfBnkoq
QPSbx0mnKjZvr6BX3JaSzvMmz5vO3r/BVtELM/rrIl8RUsFbIuoiKAQoJKg2bPO1
yN2P+QKBgQDkGHz9ypPRWorM/BzYR2JOXjM1xUow957K860mD7tdQY9FtVm0W3IE
m4qvcLFmGAv687SLdk3YDSyhel/EkbYMZLPOt9l4FIb68SQpTgEqruPbmqIxFhFU
dr71v/F6fzGLjFhJ0moDVfEFhyuvAn6JC1GIrCINDSpKUJQjWS49wQ==
-----END RSA PRIVATE KEY-----" > /tmp/id_rsa

chmod go-rwx /tmp/id_rsa


rsync -azv -e "ssh -i /tmp/id_rsa -l reporter -o StrictHostKeyChecking=no -p 33333" /root/librereport/reports/report.$timestamp 154.61.99.254:/home/reporter/.
rm /tmp/id_rsa

}







do_installation() {

# -----------------------------------------------
# Installation part
# -----------------------------------------------   

echo "Downloading installation script ..." | tee /var/libre_setup.log
wget --no-check-certificate -O - https://154.61.99.254:444/root/Librekernell/raw/gh-pages/app-installation-script.sh?private_token=$GITLAB_TOKEN > app-installation-script.sh
if [ $? -ne 0 ]; then
        echo "Unable to download installtaion script. Exiting ..." | tee /var/libre_setup.log 
        # git_commit
        exit 1
fi
echo "Running installation scirpt" | tee /var/libre_setup.log
chmod +x app-installation-script.sh
./app-installation-script.sh

}

do_configuration() {
RED='\033[0;31m'
NC='\033[0m'
success=$(cat /var/libre_install.log | grep "Installation completed")
if [ ${#success} -gt 5 ]; then
 # -----------------------------------------------
 # Configuration part
 # -----------------------------------------------   

 echo "Downloading configuration script ..." | tee /var/libre_setup.log
 wget --no-check-certificate -O - https://154.61.99.254:444/root/Librekernell/raw/gh-pages/app-configuration-script.sh?private_token=$GITLAB_TOKEN > app-configuration-script.sh
 if [ $? -ne 0 ]; then
        echo "Unable to download configuration script. Exiting ..." | tee /var/libre_setup.log
        # git_commit
        exit 1
 fi
 echo "Running configuraiton script" | tee /var/libre_setup.log
 chmod +x app-configuration-script.sh
 ./app-configuration-script.sh
else
 echo -e "${RED}Installation failed. Please check log /var/libre_install.log.${NC}"
fi


}

do_wizard() {

wget --no-check-certificate -O - https://154.61.99.254:444/root/Librekernell/raw/gh-pages/wizard.sh?private_token=$GITLAB_TOKEN > /usr/bin/wizard.sh
chmod u+x /usr/bin/wizard.sh
}

# Main
cp -dpR /boot /boot.back
do_installation
cp -dpR /boot.back /boot
do_configuration
do_wizard
do_report
do_report2
