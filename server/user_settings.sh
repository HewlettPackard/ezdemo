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

set -euo pipefail

USER_ID=$(jq 'if .user == "" then "unknown user" else .user end' user.settings)
PROJECT_ID=$(jq 'if has("project_id") then .project_id else "ecp demo" end' user.settings)
IS_VERBOSE=$(jq 'if has("is_verbose") then .is_verbose else false end' user.settings)
IS_RUNTIME=$(jq 'if has("is_runtime") then .is_runtime else true end' user.settings)
IS_MLOPS=$(jq 'if has("is_mlops") then .is_mlops else false end' user.settings)
IS_MAPR=$(jq 'if has("is_mapr") then .is_mapr else false end' user.settings)
IS_GPU=$(jq 'if has("is_gpu") then .is_gpu else false end' user.settings)
IS_HA=$(jq 'if has("is_ha") then .is_ha else false end' user.settings)
IS_MAPR_HA=$(jq 'if has("is_mapr_ha") then .is_mapr_ha else true end' user.settings)
INSTALL_AD=$(jq 'if has("install_ad") then .install_ad else true end' user.settings)
ADMIN_PASSWORD=$(jq 'if has("admin_password") then .admin_password else "admin123" end' user.settings)
EXTRA_TAGS=$(jq -r 'if has("extra_tags") then .extra_tags else "" end' user.settings)

AD_REALM="SAMDOM.EXAMPLE.COM"
