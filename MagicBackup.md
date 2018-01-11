#Target: https://www.cageos.org/index.php?page=apps&section=DecentralizedBackup
##User lose his Librerouter -> User recover all from a new Librerouter from the Tahoe grid with just a password -> recover again all your data and configuration even if your Librerouter breaks down completely.

##What means technically? : 
### That we need to backup system files and personal data files in an encrypted tahoe space private.
### That the gpg keys to access this private space need to be stored in a public space. So the keys need to be stored encrypted with a password in there with an ID that will by provided to the user in other to automatize the recovery of the system from scratch.
###Asumptions: Tahohe has a public space where no keys are required to acces but just a user and we need to be sure the other users from the grid canT delete those files with unique IDs with the recovery ecryption keys.

###Posibile scenarios:  
 - Tahoe runs and the user is fresh Librerouter, no recovery is required, just backup and setup recovery keys in public space
 - Tahoe runs and it is a user trying to recover previous Librerouter Tahoe encryption keys. A restore to a previous system config and user data.

##app-installation-script installs all necesary software packages (i2p tor tahoe owncloud)
##app-configuration-script configure and runs all necesary software (setup the CRON backup scripts)
##post-configuration-script automatizes the setup of the keys with a password in tahohe spaces and launch a wizards with human interaction to make that process visible to the end user and store/place passwords and keys where the user wishes

##post-configuration-script: Functions dedicated to this role:
 - a) Check i2p and tor are setup and test runing proceses.
 - b) Intinilize TOR I2P conectors for tahoe
 - c) Ask if this a recovery system or a fresh Librerouter 
 - d) ask for password if recovery
 - e) initialize tahoes in TOR and I2p
 - f) If recovery then locate keys files and extract files from the public space of tahoe with the passwd
 - g) Check if password decompres succesfully decrypt the keys file
 - h) Use those keys to acces private space of the user
 - i) Initialize tahohe with previous keys
 - j) Extract all data from private space
 - k) restore configuration files of Librerouter system
 - l) Resote user home owncloud data folder and owncloud db withuser encryption keys for backend.

#Manual versus script versus GUI wizard

**In script can be two choises:** 
1. new device from scratch - steps 1-6
2. Restore lost device  - steps 9-17

**Steps:**

1. User generates tahoe keys 
Keys generated after run 'tahoe create-node' or 'tahoe create-client'
Q: Routers will participate in tahoe grid as storage node or can be only clients?
BOTH

2. User encrypts all keys in a zip file with long password
This part do script zipped: script ask password from user in interactive mode and provide feedback with results of retrieveing and decrypt
Inputs: password 25 caharacthers and city (date and hour from an ntp will be used for timezone in file)
Output recovery mode: findings of the file  and try to decrypt
Output fresh system: Generate cmpresed file with encrypted files names inside with the name date-time-first2paswordchacarters.zip

3. User stored part of the password securely :User saves this password in 2 sheet of papers and give relatives or confident relationship persons

6. User uses private encrypt space of tahoe for backuping part of the Librerouter configuration files,keys , certificates, generated sshs,generated dbpass, dbs , identities and data from him itself example owncloud home directory
Use another script called Tahoe-backup

7. User lost his librerouter device

8. User buy a new one 

9. New device connect public space of tahoe (no key are required ASUPMTION2 is true?)
Tahoe generated new keys after first run but would not be needed to backup if this is a recovery of the system.

10. Wizard: ask user if fresh system or not take is zip file from Public space
  Find by 2 first caracters of the passwords in files
 
11. Script decrypt zip 
    Script ask password and date of first bought of librerouetr

12. User recovery old tahoe keys 
13. Script replace keys with old ones 
    Script restart tahoe and connect via TOR and I2P

14. Scripts restore all like magic and reboot system
