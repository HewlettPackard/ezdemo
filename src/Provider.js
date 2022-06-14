import React, { Fragment } from 'react'
import { Button, Card, Layer, Select, TextInput } from 'grommet'
import { Amazon, Connect, Edge, Redhat, Vmware } from 'grommet-icons'
import regions from './regions';

function Provider() {
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

  const Login = () => {
    console.dir(provider)

  const setRegion = (region) => {
    provider === "AWS" ? setConfig(old => ( { ...old, aws_region: region } ) ) : setConfig(old => ( { ...old, azure_region: region } ) )
  }

  return(
    <Fragment>
      <Button label="Login"onClick={ () => setLayer(16) } />
      { layer === 16 && (
        <Layer animate modal onClickOutside={ () => setLayer(0) } plain={false}>
          <Card>
            <Select options={providers} closeOnChange placeholder="Select provider" 
              onChange={ (e) => setProvider(e.target.value) } />
            
            {
              provider && Object.keys(config).filter(c => c.startsWith(provider.toLowerCase())).filter(c => !c.includes('region')).map(c => {
                return <TextInput icon={ icons[provider] } key={c} placeholder={c} onChange={ (val) => setConfig(old => ( { ...old, [c]: val.target.value } ) ) } />
              }
              )
            }
            { cloudProviders.includes(provider) && 
              <Select options={regions[provider.toLowerCase()]} placeholder="Select location" 
              onChange={ (e) => setRegion(e.target.value) }
              icon={ icons[provider] } /> }

            <Button label="Connect" icon={<Connect />}
              onClick={ () => Login() } />
              </Card>
              </Layer>
            )}
    </Fragment>
  )
  }
}

export default Provider;