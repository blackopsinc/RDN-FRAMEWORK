#!/bin/sh

# Install required Perl modules
apt-get update -qq
apt-get install -y libjson-perl libdbi-perl libdbd-mysql-perl

chown -v www-data.www-data /var/www/cgi-bin/* -R
chmod -v 755 /var/www/cgi-bin/rdn_server/client
chmod -v 755 /var/www/cgi-bin/rdn_server/rdn_api
chmod -v 755 /var/www/cgi-bin/rdn_server/rdn_console
chmod -v 755 /var/www/cgi-bin/rdn_server/rdn_login
chmod -v 755 /var/www/cgi-bin/rdn_server/rdn_security
chmod -v 755 /var/www/cgi-bin/rdn_server/rdn_webcmd
chmod -v 755 /var/www/cgi-bin/rdn_server/rdn_webcmd_server
chmod -v 755 /var/www/cgi-bin/rdn_server/secure*
mv /var/www/cgi-bin/rdn_server/secure* /usr/bin
chmod -v 666 /var/www/cgi-bin/rdn_server/config.conf
chmod -v 400 /var/www/cgi-bin/rdn_server/rdn_database
chmod -v 400 /var/www/cgi-bin/rdn_server/rdn_session
chmod -v 600 /var/www/cgi-bin/rdn_server/.rdn_keystore
