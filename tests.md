Important notes before testing : 

- Do NOT try to install the scripts via ssh session.
- The scripts FAIL if you do that, due to problems with ethernet connection.
- install the scripts via direct console access.
- NEVER save any certificate of any website in the browsers.
(the certificate you will install isn't one generate by squid)
- Incognito mode is NOT allowed in the tests.
- Do NOT test using Firefox.

Always provide evidence for the issues you open:
Evidence takes the form of:

a) nslookup logs
b) ping logs
c) capture filtering by port and ip resolved
d) screen capture of the browser
e) screen capture of the wireshark in diferent tcp packets
f) logs from librerouter.

[1. Testing http]

This step is for http testing.
Just open any http web page to see if http works.

http://ebay.com
http://www.elmundo.es
http://www.abc.es

[2. Testing https (NON HSTS)]

This spet is for https testing for non HSTS web pages.
Please open any https (NON HSTS) web page to see if https works.
We need to find the hsts method to dinamically downgrade all https site to http
(apart of the diferent solution to be with the separate browser and CA installed)

https://www.amazon.de
https://best.aliexpress.com

If you see Internet widgits in the certificate it means that the ssl tunnel is bumped
The diference with hsts is the errors concretelly does not shows hsts as cause of fail.


[3. Testing https(HSTS)] evidence in browser will show keyword hsts if not then wireshark evidence!

This step is for https testing for HSTS web pages.
Please open any https (HSTS) web page to see if https works.

https://accounts.google.com/
https://gmail.com
https://www.dropbox.com/
https://login.live.com
https://www.skype.com
https://www.twitter.com
https://www.facebook.com

[4. Testing antivirus]

This step is for testing if virus detection works.
Please go to http://www.eicar.org/85-0-Download.html
and try to download virus test files (with http and SSL). 

Direct links for downloading.
http://www.eicar.org/download/eicar.com
https://secure.eicar.org/eicar.com

If virus detection works, you should be redirected to virus warning page.


[5. Testing content filtering]

This step is for testing if web page's content filtering works.
Please open any porn web page to see if it works.

For example http://www.xxx.com/

If content filtering works, you should be redirected to ecapguardian warning page.


[6. Testing Services]

This step is for testing if local services works.
Local services should be tested for
6.1 Direct access
6.2 Redirection from related domains(i.e. google.com -> yacy.librenet)
6.3 Access from tor network (Please see point 7)
6.4 Access from i2p network (Please see point 8)

6.1 Direct access testing
Please go to this web pages 
http://yacy.librenet
http://owncloud.librenet
http://mailpile.librenet
http://friendica.librenet
http://easyrtc.librenet
http://webmin.librenet

6.2 Redirection testing
(Please note that you need to disable HSTS checking in your browser 
or use browser with disabled HSTS, for example seamonkey)

Here is how it should work  
google.com -> redirected to -> yacy.librenet
dropbox.com -> redirected to -> owncloud.librenet
skype.com -> redirected to -> easyrtc.librenet
facebook.com -> redirected to -> friendica.librenet
gmail.com -> redirected to -> mailpile.librenet


[7. Testing Tor]
This step is for testing
7.1 Tor network access
7.2 Hor hidden services

7.1 Testing tor network access
Please open any .onion domain to see if tor network is accessible.

for example http://3g2upl4pq6kufc4m.onion/

7.2 Testing tor hidden services
Please run "services" command in your terminal(in LibreRouter) to see 
local services info. Find column "Tor domain" and get .onion urls 
from output and try to open them.
(Please Note that you need to do this testing (7.2) from other computer 
connected to tor network. (not your LibreRouter or any client machine 
connected to LibreRouter))

[8. Testing i2p]

This step is for testing
8.1 i2p network access
8.2 i2p hidden services

8.1 Testing i2p network access
Please open any .i2p domain to see if tor network is accessible.

for example http://stats.i2p/

8.2 Testing i2p hidden services
Please run "services" command in your terminal(in LibreRouter) to see 
local services info. Find column "i2p domain" and get .i2p urls 
from output and try to open them.
(Please Note that you need to do this testing (8.2) from other computer 
connected to i2p network. (not your LibreRouter or any client machine 
connected to LibreRouter))


[9. Tecting banks access]

This step is for testing backs web pages access. 
Please open bank web page to see if its accessible directly

for example https://www.caixabank.com/


[10. Testing ads blocking]

This step is for testing advertisement blocking
Please open any web page with advertisements to see if ads have been 
blocked.

For example:
http://thestir.cafemom.com/entertainment/158359/glee_changes_already_under_way?utm_medium=sem2&utm_campaign=prism&utm_source=outbrain&utm_content=0
http://searchengineland.com/too-many-ads-above-the-fold-now-penalized-by-googles-page-layout-algo-108613
http://www.theonion.com/blogpost/please-click-on-our-websites-banner-ads-30513
http://ads-blocker.com/testing/

Tips:
Open web page without LibreRouter connected to see ads banners
Then Connect LibreRouter and open the same page.
Try to Find ads banners in same place. If no banners then ads
blocking works.

##Privacy testers: We used in the browser from the simulated client with windows 10

 - https://anonymous-proxy-servers.net/en/help/security_test.html
 - www.iprivacytools.com
 - checker.samair.ru
 - https://anonymous-proxy-servers.net/en/help/security_test.html
 - https://www.onion-router.net/Tests.html
 - analyze.privacy.net
 - https://www.maxa-tools.com/cookie-privacy.php
 - https://panopticlick.eff.org/
 - https://www.perfect-privacy.com/german/webrtc-leaktest/
 - https://www.browserleaks.com/
 - browserspy.dk

Index of more things to test:

    a) https to onion
    b) https to i2p
    c) http to onion
    d) http to i2p
    e) http with ads to internet
    f) https with ads to internet
    g) https with not allowed content porn to internet
    h) https to a bank
    i) http to a bad domain
    h) https to a bad domain
    i) https to a good domain that tries to exploit the browser via flash exploit
    h) https that tries to download a exe file with virus.
    i) http conecting to a place but this conection matches a botnet signature.
    j) ssh to a server between the librerouter and internet (internal lan of the user , external side of the librerouter)
    k) tahoe trying to use TOR or I2P addresses.
    l) user browser a keyword in browser formularie > browser tries to query google or duckduckgo or bing for that search.
    m) Attacks to local services url from from TOR or I2P.
    n) any local machine tries to go to youtube> how to macke interactive the procces where librerouter ask to the users to allow or not.
    o) any web tries to track via installing certificates like fb of gmail or google to spy on users.
    p) how the user will allow or not any IoT while is blocked in librerouter?
    q) what we do with udp?
    r) udp dns request that not goes to unbound?
    s) udp p2p trafic from emule?
    t) udp others?
    u) icmp ping to any IP
    v) non http,icmp,https,dns traffic (how layer 7 will try to identify the protocol and alert the user to allow or not)
    w) a request from xmmp federation from internet or from TOR or I2P
    x) to allow or not javascript,flash, etc on preallowed white and black list
    y) yacy trying to go by TOR or I2P
    z) prosody trying to conect via over TOR
    a1) webrtc protocol
    a2) hsts via browser direct entry for example gmaik push enter key
    a3) hsts via browser corrected entry form for example https://www.gmail.com enter key

