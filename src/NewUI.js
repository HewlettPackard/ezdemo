import React from 'react'
import { Box, Notification, Button, DataTable, Layer, Card, Select, TextInput, NameValueList, NameValuePair, List } from 'grommet'
import { Add, Edge, Amazon, Vmware, Connect, Redhat } from 'grommet-icons'
import regions from './regions';

function NewUI() {
  const [layer, setLayer] = React.useState()
  const [provider, setProvider] = React.useState();
  const cloudProviders = ["AWS", "Azure"];
  const providers = cloudProviders.concat(["vCenter", "oVirt"]);

  const awsconfig = {"aws_access_key": "", "aws_secret_key": "", "aws_region": ""};
  const azureconfig = {"azure_appId": "", "azure_password": "", "azure_subscription": "", "azure_tenant": "", "azure_region": ""};
  const vcenterconfig = {"vcenter_server": "", "vcenter_username": "", "vcenter_password": "", "vcenter_location": ""};
  const ovirtconfig = {"ovirt_server": "", "ovirt_username": "", "ovirt_password": "", "ovirt_location": ""};
  const [config, setConfig] = React.useState({ ...awsconfig, ...azureconfig, ...vcenterconfig, ...ovirtconfig })
  const icons = {
    AWS: <Amazon />,
    Azure: <Edge />,
    vCenter: <Vmware />,
    oVirt: <Redhat />
  }

  const setRegion = (region) => {
    provider === "AWS" ? setConfig(old => ( { ...old, aws_region: region } ) ) : setConfig(old => ( { ...old, azure_region: region } ) )
  }

  return(
    <Box fill overflow="auto" flex align="start" margin='small'>
      <Notification message="This UI is under development, things may work!" status="critical" title="Experimental Features" toast global />
      <Button label="New Project" icon={<Add />} plain onClick={ () => setLayer(32) } />
      {/* <DataTable
        columns={[
          {header: "Project", property: "folder", primary: true},
          {header: "Environment", property: "target"}]}
          data={[{"folder":"Test1","target":"aws"},{"folder":"Test2","target":"azure"}]} sortable size="small" onSelect select="selectthis()" paginate /> */}
      <Box align="start" justify="start" fill>
        <Button label="Login"onClick={ () => setLayer(16) } />
        {layer === 16 && (
        <Layer animate modal onClickOutside={ () => setLayer(0) } plain={false}>
          <Card>
            <Select options={providers} closeOnChange placeholder="Select provider" 
              onChange={ (e) => setProvider(e.target.value) } />
            
            {
              Object.keys(config).filter(c => c.startsWith(provider.toLowerCase())).map(c => {
                 return <TextInput icon={ icons[provider] } key={c} />
                }
                )
            }
            { cloudProviders.includes(provider) && 
              <Select options={regions[provider.toLowerCase()]} placeholder="Select location" 
                onChange={ (e) => setRegion(e.target.value) }
                icon={ icons[provider] } /> }

            <Button label="Connect" icon={<Connect />} />
          </Card>
        </Layer>
    )}
        {layer === 32 && (
        <Layer animate modal onClickOutside={ () => setLayer(0) } plain={false}>
          <NameValueList layout="column">
            <NameValuePair name="gpu" />
            <NameValuePair name="mapr" />
          </NameValueList>
        </Layer>
    )}
      </Box>
        <pre>{ JSON.stringify(provider, 0,2) }</pre>
        <pre>{ JSON.stringify(config, 0,2) }</pre>
    </Box>
  );
}

export default NewUI;
