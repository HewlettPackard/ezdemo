# TODO for DC deployment

## Settings

- [x] Create AD if none exist/selected

- [x] Select number of nodes per type (picasso/k8s/mapr)

  - can be provided in dc.ini:

      controller_count

      gateway_count

      picasso_count

      k8s_count

      mapr_count

- [ ] Output while running ansible-create.sh

- [ ] GPU Worker support

- [ ] refresh_files.sh to check and update if download_url provided by dc.ini

## UI

request ovirt/vcenter/kvm credentials -> list/create/select DC/cluster/folder/datastore/vswitch
