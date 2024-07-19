# RDN - Red Devil Networks 

<!--<p align="center">
  <img src="https://github.com/blackopsinc/RDN/blob/main/rdn_server/html/css/default/rdn_logo.jpg?raw=true" width="100%"/>
</p>-->

Migrated RDN CnC Framework to docker/codespace - Built this 20 years ago!

- Included Web Client Capabilities ***(Simple Web Client for testing)***
- Removed Exploit, and Build Framework ***(Reduced Function)***
- Manual update database _hosts table via SQL if you want to add another remote host for CnC ***(Reduced Function)***
  
<p align="center">
  <img src="https://github.com/blackopsinc/RDN-Framework/blob/main/rdn_server/html/css/default/rdn_overview.jpg?raw=true" width="100%"/>
</p>



# Installation Instructions (Codespace)

1. Modify rdn_server/cgi-bin/rdn_server/config.conf 
```perl
#
# Local Setup
#
#$rdn_hostname = "localhost";
#$rdn_server = "http://" . $rdn_hostname;
#$rdn_port = ":8080";
#
# Codespace Setup example
# 
$rdn_hostname = "<codespacename>-8080.app.github.dev";
$rdn_server = "https://" . $rdn_hostname;
```
2. Run Docker Compose
```console
@blackopsinc ➜ .../RDN (main) $ docker-compose up -d
```
3. Open Browser to Codespace
``` code
https://<codespacename>-8080.app.github.dev/
username: admin
password: changeme
```
4. To add webclient to remote host
```console
docker exec -ti <containerid> /bin/bash
mysql -u root -p rdn
password: changeme
```
``` sql
INSERT INTO `_hosts` VALUES (1,'web','nix','','','http://localhost:8080/server/client?cmd=','localhost','web');
```
***Note: The URL to the Webclient should be formatted like this "http://localhost:8080/server/client?cmd="***
