#Built updated version TOR browser framework able to  enroute TOR,i2p,zeronet domains with some features: portable, compatible with antivirus, portable proxies and addons, runing in an encrypted usb stick with portable encryption software and easy to use able to run in linux kernel 3 and windows 10

Old version to be updated:
https://37.148.137.138:1011/public.php?service=files&t=0e4890970e683f0b2169939679debd33

pass 61676167



0. We need to use a USB that have writable protection. We need to find encryption poratble framework for Linux and Windows that do not interacts with corporate protections like Antivirues , DLPs and endpoint protection crap.
1. Being Portable in Linux and Windows (2 executables)
2. To use HAproxy, Foxyproxy similar  to being able to redirect TOR,I2P, Freenet,Zeronet and other hidden services to the proper proxy running simultaneously in the background that not need to be detected as malicious by antivirus.
3. To have installed some security functions addons.
4. To have capability to being update without breaking itself.
5. That would be able to retrieve a CA via wizard and ssh from the Librerouter when insside his LAN to install it in itself for bumping.
6. That has disabled HSTS
7. That is able to detect the proxy from the system or manually alocate credentials to be able to go through corporate networks.
8. Be able to detect filtering in corporate networks.
9. That retrieve the hidden addresses from the clients Librerouter and storage in the initial opening session as a menu to reach home.



a) Windows xp,7,10 portability is required
b) Linux Ubuntu debian portability is required.

3. Initial Task:
Result of analisys of the actual broswer i gave to you in the owncloud: which tools are used?
Find opensource encryption program poratable for the  usb that works in linux and windows
TEST in the USB with writable protection.
Works? Decrypt is portable and not interact with corporate end user protection crap?
Start to use latest version of the TOR browser for linux and windows
Disable hsts in both version
Add engines for i2p, freenet, zeronet, etc
Add proxy redirection capabilities
Test
All good? redirects hidden services to the proper engines and do not act with AV DLP IDS IPS and crappy endpoint solution?
Add proxy use capabilites via using a framweork for wizard that runs firstime the broweser is always opening doing check over the network to reach internet.

1. Result of analisys of the actual broswer i gave to you in the owncloud: which tools are used? - Done.  
2. Find opensource encryption program poratable for the  usb that works in linux and windows - in process.

3. Updated browser on latest version (can send it to you, 60 MB). 
4. Tested it on Linux. Found the reason why doesn't work i2p (report on email).
5. Tested updating the browser on Ubuntu 14.04 LTS. I updated it on Ubuntu several times. After the first updating
everything worked, but after restarting the browser, it stopped working. The error is "Unable to find the proxy server" when foxyproxy is disabled or enabled. Then I updated another copy of your browser foxyproxy crashed.
6. Tested updating the browser on Windows 7. The TOR, foxyproxy does not work
7. I found a good encrypting program AES Crupt. This program is opensource, portable in liuux and windows.
It can be run from command line in linux and windows. I have a question, whether all the browser files should be encrypted or only personal data: session data, history and the like. Does the encryption and decryption process must be automated?
8. After updating the foxyproxy standart is not verified for use in Tor browser. Looks like this is for safety reasons. After enabling foxyproxy I checked all proxy settings and patterns and they are the same like before ubdating. So after updating browser it is necessary to reactivate foxyproxy. I found the problem with starting portable version of i2p client. It doesn'twork before and after updating the browser.
9. I did a some review of the free alternatives of foxyproxy and for now it was failed to find alternative whitch maintain a regular expression. Support service of foxyproxy recommended to use the newest foxyproxy version. But after updating foxyproxy the Tor browser can not be updated because of an error. Perhaps easier to enable foxyproxy extension after updating Top browser with further automation.
10. Tried to find the HSTS disabling method.
    The result is to need to add our CA to the broswer's certificate store.
    Because we need ssl MITM.
