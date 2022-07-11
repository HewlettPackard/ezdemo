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

Any lines after "#### Custom ####" will be copied as is to provide additional information (ie, AD settings).

- If you set install_ad=false in user settings, you need to provide AD access information

- Configure proxy settings if behind one

- You may also provide local repository for Data Fabric packages

```ini
#### Custom ####
ad_server=
ad_domain=example.com
ad_bind_dn=CN=Administrator,CN=Users,DC=example,DC=com
ad_bind_pwd=
ad_security_protocol=ldap # defaults to ldaps
ad_bind_type=search_bind # this is default
ad_base_dn=DC=example,DC=com
ad_user_attribute=sAMAccountName # this is default
ad_group_attribute=member # defaults to memberOf
ad_type=Active Directory # this is default
ad_port=389
ad_admin_group=CN=Administrators,CN=Users,DC=example,DC=com
ad_member_group=CN=Users,DC=example,DC=com
ad_verify_peer=false # this is not used, always defaults to false

http_proxy= ### add http proxy environment to all nodes (NOT TESTED)
https_proxy= ### add https proxy environment to all nodes (NOT TESTED)
no_proxy= ### add no proxy environment to all nodes (NOT TESTED)

mapr_monitoring=false
mapr_repo=http://www.local.site/repos/mapr/releases/

...
```

## Requirements

- CentOS 7 template:

  - vcenter_template_user is configured with [paswordless sudo](https://www.google.com/search?q=centos+7+passwordless+sudo)

  - Root volume with 400GB size

~~- Ubuntu 20.04 template (if you want to deploy Standalone Data Fabric):~~

~~- vcenter_mapr_template_user is configured with [paswordless sudo](https://www.google.com/search?q=ubuntu+20.04+passwordless+sudo)~~

- Rocky Linux 8 template for Data Fabric:

  - vcenter_mapr_template_user configured with passwordless sudo (same as CentOS7)

  - Has cloud-init and perl packages installed (for dynamic IP assignment)

  - Root volume with 400GB size

## TODO

Refer to [TODO](./TODO.md) file
