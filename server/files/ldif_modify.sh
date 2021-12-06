#!/bin/bash

set -e

ldapmodify -H ldap://localhost:389 \
    -D 'cn=Administrator,CN=Users,DC=samdom,DC=example,DC=com' \
    -f /home/centos/ad_set_posix_classes.ldif \
    -w '5ambaPwd@' -c 2>&1 >ad_set_posix_classes.log