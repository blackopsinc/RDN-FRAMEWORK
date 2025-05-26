#!/usr/bin/perl
################################################
#      Copyright 2004-2025 RDN Networks        #
#      Main Entry Point with Authentication    #
################################################

use CGI;
$rdn = new CGI;

require "/var/www/cgi-bin/rdn_server/config.conf";

# Redirect to authentication check
print "Location: $rdn_server$rdn_port/$rdn_bin/cgi-bin/rdn_server/rdn_auth_check\n\n";
exit;
