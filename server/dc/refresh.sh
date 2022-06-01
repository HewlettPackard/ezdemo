#!/usr/bin/env bash
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


### 
### Called from ../refresh_files.sh to override with user-provided vars
###

## Clear ssh proxy
NET=$(grep -w 'vm_network' vars.ini | cut -d'"' -f2 | cut -d/ -f1)
NETW="${NET%.*}"
sed -i "s/Host 10.1.0/Host ${NETW}/"  ~/.ssh/config
sed -i '/^Host ezdemo_gateway/,+4d'  ~/.ssh/config
sed -i '/ProxyJump ezdemo_gateway/d'  ~/.ssh/config

## Update download url for epic installer - if provided
URL=$(grep -w 'download_url' vars.ini | cut -d= -f2-)
[ ! -z "${URL}" ] && export EPIC_DL_URL="${URL}"

## Include custom settings (ie, AD settings)
export CUSTOM_INI=$(grep -A250 '#### Custom ####' vars.ini | grep -v -e '^#' -e '^\s*$')
