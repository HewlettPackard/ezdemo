#!/bin/bash
# =============================================================================
# Copyright 2022 Hewlett Packard Enterprise
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
# =============================================================================

set -e

sudo docker pull rsippl/samba-ad-dc > /dev/null

sudo docker run --privileged --restart=unless-stopped \
    -p 53:53 -p 53:53/udp -p 88:88 -p 88:88/udp -p 135:135 -p 137-138:137-138/udp -p 139:139 -p 389:389 \
    -p 389:389/udp -p 445:445 -p 464:464 -p 464:464/udp -p 636:636 -p 1024-1044:1024-1044 -p 3268-3269:3268-3269 \
    -e "SAMBA_DOMAIN=samdom" \
    -e "SAMBA_REALM=samdom.example.com" \
    -e "SAMBA_ADMIN_PASSWORD=5ambaPwd@" \
    -e "ROOT_PASSWORD=R00tPwd@" \
    -e "LDAP_ALLOW_INSECURE=true" \
    -e "SAMBA_HOST_IP=$(hostname --all-ip-addresses |cut -f 1 -d' ')" \
    -v /home/centos/ad_user_setup.sh:/usr/local/bin/custom.sh \
    --name samdom \
    --dns 127.0.0.1 \
    -d \
    --entrypoint "/bin/bash" \
    rsippl/samba-ad-dc \
    -c "chmod +x /usr/local/bin/custom.sh &&. /init.sh app:start"
