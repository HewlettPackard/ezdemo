# On-premise Deployment

## Supported targets

Tested on:

- Vmware: Supported versions by the [Ansible module](https://galaxy.ansible.com/community/vmware)

- oVirt: Supported versions by the [Ansible module](https://galaxy.ansible.com/ovirt/ovirt)

- Proxmox: Supported versions by the [Proxmox module](https://docs.ansible.com/ansible/latest/collections/community/general/proxmox_kvm_module.html)

- Libvirt (KVM): Supported versions by the [Libvirt module](https://galaxy.ansible.com/community/libvirt)

## Configuration

Use example dc.ini files specific to the target platform

If dc.ini exist where you run start.sh script, it will be automatically mounted to the container. If not, manually copy the dc.ini file under /app/server/dc folder inside the container.

## Supported options

Override default node counts with following settings, use numbers (smaller than minimums will be overriden)

- picasso_count=

- k8s_count=

- mapr_count=

Provide installer URL (defaults to latest)

- download_url=

Additional (custom) information

50 lines after "#### Custom ####" will be copied as is to provide additional information (ie, AD settings).

- If you set install_ad=false in user settings, you need to provide AD access information

 ```ini
#### Custom ####
ad_server=""
ad_domain="example.com"
ad_username="Administrator"
bind_dn="CN=Administrator,CN=Users,DC=example,DC=com"
bind_pwd=""
security_protocol="ldap" # defaults to ldaps
bind_type="search_bind" # this is default
base_dn="DC=example,DC=com"
user_attribute="sAMAccountName" # this is default
group_attribute="memberOf" # defaults to member
type="Active Directory" # this is default
port=389
external_groups="CN=Administrators,CN=Users,DC=example,DC=com"
verify_peer=false # this is not used, always defaults to false

http_proxy= ### add http proxy environment to all nodes (NOT TESTED)
https_proxy= ### add https proxy environment to all nodes (NOT TESTED)
no_proxy= ### add no proxy environment to all nodes (NOT TESTED)

mapr_monitoring=false
mapr_repo=http://www.local.site/repos/mapr/releases/

...
 ```

## Requirements

- CentOS 7 template:

  - template_user is configured with [paswordless sudo](https://www.google.com/search?q=centos+7+passwordless+sudo)

  - Root volume with min 400GB

- Ubuntu 20.04 template (if you want to deploy Standalone Data Fabric):

  - mapr_template_user is configured with [paswordless sudo](https://www.google.com/search?q=ubuntu+20.04+passwordless+sudo)

## TODO

Refer to [TODO](./TODO.md) file
