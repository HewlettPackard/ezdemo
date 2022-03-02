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

# allow weak passwords - easier to demo
samba-tool domain passwordsettings set --complexity=off

# set password expiration to highest possible value, default is 43
samba-tool domain passwordsettings set --max-pwd-age=999

# Create DemoTenantUsers group and a user ad_user1, ad_user2
samba-tool group add DemoTenantUsers
samba-tool user create ad_user1 pass123
samba-tool group addmembers DemoTenantUsers ad_user1

samba-tool user create ad_user2 pass123
samba-tool group addmembers DemoTenantUsers ad_user2

samba-tool user create ad_user3 pass123
samba-tool group addmembers DemoTenantUsers ad_user3

samba-tool user create ad_user4 pass123
samba-tool group addmembers DemoTenantUsers ad_user4

samba-tool user create ad_user5 pass123
samba-tool group addmembers DemoTenantUsers ad_user5

samba-tool user create ad_user6 pass123
samba-tool group addmembers DemoTenantUsers ad_user6

samba-tool user create ad_user7 pass123
samba-tool group addmembers DemoTenantUsers ad_user7

samba-tool user create ad_user8 pass123
samba-tool group addmembers DemoTenantUsers ad_user8

samba-tool user create ad_user9 pass123
samba-tool group addmembers DemoTenantUsers ad_user9

samba-tool user create ad_user10 pass123
samba-tool group addmembers DemoTenantUsers ad_user10

# Create DemoTenantAdmins group and a user ad_admin1, ad_admin2
samba-tool group add DemoTenantAdmins
samba-tool user create ad_admin1 pass123
samba-tool group addmembers DemoTenantAdmins ad_admin1

samba-tool user create ad_admin2 pass123
samba-tool group addmembers DemoTenantAdmins ad_admin2

samba-tool user create ad_admin3 pass123
samba-tool group addmembers DemoTenantAdmins ad_admin3

samba-tool user create ad_admin4 pass123
samba-tool group addmembers DemoTenantAdmins ad_admin4

samba-tool user create ad_admin5 pass123
samba-tool group addmembers DemoTenantAdmins ad_admin5

samba-tool user create ad_admin6 pass123
samba-tool group addmembers DemoTenantAdmins ad_admin6

samba-tool user create ad_admin7 pass123
samba-tool group addmembers DemoTenantAdmins ad_admin7

samba-tool user create ad_admin8 pass123
samba-tool group addmembers DemoTenantAdmins ad_admin8

samba-tool user create ad_admin9 pass123
samba-tool group addmembers DemoTenantAdmins ad_admin9

samba-tool user create ad_admin10 pass123
samba-tool group addmembers DemoTenantAdmins ad_admin10
