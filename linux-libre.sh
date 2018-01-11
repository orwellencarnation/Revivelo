#!/bin/bash

####
#### We are testing this version of kernel, for check, only need run it before that installation file.
####

# Add repo
echo 'Adding repo...'
echo 'deb https://linux-libre.fsfla.org/pub/linux-libre/freesh/ freesh main' > /etc/apt/sources.list.d/linux-libre.list
wget --no-check-certificate -O - https://jxself.org/gpg.inc | apt-key add - >> /var/linux-libre.log

# Before install we need apt-transport-https package.
echo 'Installing dependencies...'
apt-get install -y --force-yes apt-transport-https >> /var/linux-libre.log

# Update repos
echo 'Updating repos...'
apt-get update >> /var/linux-libre.log


# Install linux libre kernel latest version
echo 'Installing linux libre kernel...'
apt-get install -y --force-yes linux-libre >> /var/linux-libre.log

# Showing package of new kernel.
dpkg -s linux-libre
echo 'Kernel installation completed'

