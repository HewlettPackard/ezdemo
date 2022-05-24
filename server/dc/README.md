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

Override default node counts using (overrides is_mlops, is_ha and is_mapr_ha user settings)

- picasso_count=

- k8s_count=

- mapr_count=

Provide installer URL (defaults to latest)

- download_url=

Additional (custom) information

50 lines after "#### Custom ####" will be copied as is to provide additional information (ie, AD settings).

- If you chose not to install_ad in user settings, you need to provide AD access information

 ```ini
 #### Custom ####
bind_pwd=""
user_attribute="sAMAccountName"
bind_dn="CN=Administrator,CN=Users,DC=example,DC=com"
bind_type="search_bind"
ad_server=""
security_protocol="ldap"
base_dn="DC=example,DC=com"
verify_peer="false"
type="Active Directory"
port="389"
external_groups="CN=Administrators,CN=Users,DC=example,DC=com"
group_attribute="member"
ad_domain="example.com"

ad_username="Administrator"
ad_password=""

 ```

## Requirements

- CentOS 7 template:

  - template_user is configured with [paswordless sudo](https://www.google.com/search?q=centos+7+passwordless+sudo)

  - Root volume with min 400GB

- Ubuntu 20.04 template (if you want to deploy Standalone Data Fabric):

  - mapr_template_user is configured with [paswordless sudo](https://www.google.com/search?q=ubuntu+20.04+passwordless+sudo)

## TODO

Refer to [TODO](./TODO.md) file
