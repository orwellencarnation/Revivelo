![](http://circuitosaljarafe.com/librerouter/draw2.png)


#General Purpose
Once the system is installed and configured from first time, all configuration files are copied to DFS based on Tahoe-LAFS over Tor.
In event the user lost his system, a recovery procedure may be initiated 

On new installed systems, the installation_script must install some required packages, call the configuration_script 
( new configuration is done ) and backed as new to the Tahoe-LAFS grid

If the user end installation_script with power-off option, on next boot user is prompted to select new 
o recovering intallation.

If the user start the configuration ( without power down ) is prompted for new or recovering options.

If user enter in recovering mode, the script will setup a Public client node for Tahoe and mount Public directory of users in local
mountpoint, offering the client to select who is he.

This placed encrypted files on local mountpoint, and user is prompted to enter password to decrypt it. The content of this 
decrypted file is the keys required to start Tahoe Private service. 

Once the encrypted file is decrypt, will create a new Tahoe client node for his Private backup, mount grid on local mountpoint and
restore all required files. 

If the user enters in new installation mode, the configuration_script is launched. This configuration_script MUST do , before
to reboot, these tasks:
  a) Configure CRON to start sys configuration file backups periodically ( i.e. every 240 hours )
  b) Configure a new Private Tahoe node and start it.
  c) Configure the Public Tahoe node and start it.
  d) Create encrypted id file on the Public area
  e) Start one instance of backup to the Private grid
  f) Reboot
  
The /var/spool/cront MUST be included on files for backup.

#INSTALL SCRIPT
Does, 
Check Python version, create new Python enviroment
Install rsync
Install py tahoe-lafs[tor]
Install shhfs
Install inotify ( this is for futher utilization )

#CONFIGURATION SCRIPT

Configure the Tahone Private node
Add init script to launch Tahoe Private node ONCE Tor is ready


#BACKING

Copy files from local to Tahoe Private space
This does:
  a) Read config file for SysBackup ( ie. /etc/sysback/files.txt ) 
  b) Compact all files on one SysBackup.tar.gz file
  c) Mount Tahoe Private node on local mountpoint
  d) rsync -av SysBackup.tar.gz /local_mountoint
  
Backing procedure is called first time at the end of configuration_script and before to reboot.
Backing procedure is called from CRON periodically, upgrading backup 



#RESTORE

The restore procedure is initiated ONLY if the user selects RECOVERY mode. 
In this case the configuration_script is not executed, and is executed the recover_script does:
 a) Mount local mounpoint connecting with Tahoe Public area and collect a list of files
 b) Prompt user to select file from the list that matches who is 
 c) Prompt user to enter password to decrypt the selected file
 d) If password is correct, decrypt the selected file and get the requires keys to access Tahoe Private area
 e) Mount Tahoe Private area on local mountpoint
 f) Extract from mountpoint/SysBackup.tar.gz all required configuration files with full path to /
 g) Reboot



#NOTES
 Tahoe will works with configuration hiden_ip=true and over Tor. 
 I2P will be not YET implemented due a persistance of bug on SSL23 handshake on Tahoe-lafs v1.12.1 
 Due limitations on public test Tor grid ( lack of nodes and low speed ) is highly recomended install and run
 at least 2 nodes as INTRODUCER over Tor. ( This will be our own private grid, for Public and Private storage areas )
