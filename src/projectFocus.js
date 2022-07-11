import React, { Fragment } from 'react'
import { Box, Notification, Button, TextInput, Form, FormField, DataTable, Text, Tip, CheckBox, Card, CardHeader, CardBody, CardFooter, Grid } from 'grommet'
import { Add, AddCircle, FormLock, Info, Link, Login, Refresh, StatusCritical, StatusGood, Trash, User } from 'grommet-icons'
import Modal from './Modal';

export const ProjectFocus = (props) => {
  const [remember, setRemember] = React.useState(true);
  const [layer, setLayer] = React.useState(2);
  const [alert, setAlert] = React.useState(null);
  const [credentials, setCredentials] = React.useState({ 'url': '', 'username': '', 'password': ''});
  const [platform, setPlatform] = React.useState();
  const [ml_apps, setMlapps] = React.useState();

  const { srvurl, setError, setActionButton, setSpin } = props.params;
  // load credentials if saved
  React.useEffect(() => {
    var stored = localStorage.getItem('ezmeral');
    if ( stored )
      setCredentials(JSON.parse(stored));
    // fetch app list
    fetch(`${srvurl}/mlapps`, { mode: 'cors' })
      .then(res => res.json()
        .then(data => setMlapps(data))
        .catch(error => setError(error)));
    }, [srvurl, setError]);

  const getData = (link, payload = null) => {
    if (Object.keys(credentials).length === 3) {
      setSpin(true);
      return fetch(`${srvurl}/${link}`, {
        method: 'POST',
        mode: 'cors',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ ...credentials, payload })
      })
        .then(
          res => {
            setSpin(false); // stop spinning
            if (res.ok) return res.json()
            else {
              setError(res.statusText);
              return null;
            }
          },
          error => console.dir('catch here', error)
        )
        .catch(error => {
          console.dir('or catch here', error)
          return null;
        })
    }
  }

  const connect = () => {
    if (!credentials) return;
    setLayer(0); // close the modal
    return getData('platform/connect')
      .then( config => {
        if (config) {
          setPlatform(old => ({ ...old, config }))
          if (remember && credentials) localStorage.setItem('ezmeral', JSON.stringify(credentials));
          else localStorage.removeItem('ezmeral');
          k8sc_list();
          setLayer(0);
          setSpin(false);
          setActionButton(actionButton);
        }
      })
      .catch(error => setError(error));
      ;
  }

  const k8sc_list = () => {
    getData('platform/list')
    .then(data => {
      setPlatform(old => ( { ...old, tenant: null, ...data } ) );
      setLayer(0);
    })    
  }
  
  const appOp = (op, tenant, app) => {
    var url;
    switch(op) {
      case 'test':
        url =  'platform/test';
        break;
      case 'delete':
        url =  'platform/delete';
        break;
      default:
        url =  'platform/apply';
    }
    getData(url, { app, tenant })
    .then(data => setAlert( { title: op.toUpperCase() + ' "' + app.title + '" on "' + platform.tenant.label.name + '"', message: data, status: 'normal' } ) );
    setLayer(4);
  }

  const disconnect = () => {
    setPlatform({});
    console.log("Logged out!")
  }

  const actionButton =
    <Button
      label={platform?.config?.result === 'Success' ? 'Connected as: ' + credentials.username : 'Connect to Ezmeral'}
      onClick={() => setLayer(2)}
    />

  return(
    <Box flex overflow="auto" align="start" margin='small' gap='small'>
      <Box align="start" fill='horizontal'>
        <Box direction='row' justify='between' fill='horizontal'>
          { actionButton }
          { platform?.config && <Button icon={<Refresh />} label="Refresh" onClick={ () => k8sc_list() } /> }
          { platform?.config && <Button label="Logout" onClick={ () => disconnect() } /> }
        </Box>

        {layer === 2 && (
          <Modal
            closer={()=> setLayer(0)}
            content={
              <Form
                validate='blur'
                value={ credentials }
                onSubmit={ () => connect() }
                >
                  { ['url', 'username', 'password'].map(key => 
                    <Fragment key={key}>
                      <FormField name={key} htmlfor={key} label={ key.toUpperCase() } margin='small' required>
                        <TextInput
                          icon={ key === 'url' ? <Link /> : key === 'username' ? <User /> : <FormLock /> } 
                          placeholder={key.toUpperCase()} defaultValue={ credentials[key] }
                          type={ key === 'url' ? 'url' : key === 'password' ? 'password' : 'text' }
                          onChange={ (val) => setCredentials(old => ( { ...old, [key]: val.target.value } ) ) } />
                      </FormField>
                    </Fragment>
                  )}
                <Box direction='row'>
                  <CheckBox label='Remember?' checked={remember} onChange={ () => setRemember(!remember)} />
                  <Button label='Connect' icon={<Login />} type='submit' />
                </Box>
          </Form>
          }
          />
        )}

        { platform?.config && 
          <Box fill='horizontal'>
            <Box>
              <Text size='medium' margin='small' weight='bold'>Tenants</Text>
              <DataTable key='tenants' border='bottom'
                onClickRow={ ({datum}) => setPlatform(old => ( { ...old, tenant: datum } ) ) }
                columns={[
                  {
                    property: 'status',
                    render: t => (
                      t.status === 'ready' ? <StatusGood />
                      : t.status === 'create' ? <Tip content='Create Tenant'><AddCircle /></Tip> 
                      : <Tip content={t.status}><StatusCritical /></Tip>
                      ),
                    },
                    {
                      property: 'label.name',
                      header: <Text>Name</Text>,
                      primary: true
                    },
                    {
                      property: 'label.description',
                      header: <Text>Description</Text>
                    },
                    {
                      property: 'tenant_type',
                      header: <Text>Type</Text>
                    },
                    {
                      property: 'k8s_cluster',
                      header: <Text>Cluster</Text>,
                      // render: t => (
                      //   <Text>{ platform.clusters.map(c => c.id === t.k8s_cluster ? c.name : 'None')[0] }</Text>
                      //   )
                      },
                      {
                        property: 'features.ml_project',
                        header: <Text>MLOps Project</Text>,
                        render: t => (
                            t.features?.ml_project ? <StatusGood /> : <StatusCritical />
                        ),
                      },
                ]}
                data={ platform.tenants }
              />
            </Box>
          </Box>
        }
      </Box>
      { platform?.tenant && 
      <Box>
        <Text weight='bold'>Tenant: { platform.tenant.label.name }</Text>
        <Grid columns={ { count: 4, size: 'auto' }} gap="small">
          { ml_apps?.map(app => (
              <Card key={ app.title }>
                <CardHeader><Text weight='bold'>{ app.title }</Text></CardHeader>
                <CardBody>
                  <Text truncate='tip'>{ app.description }</Text>
                </CardBody>
                <CardFooter pad={{horizontal: "small"}}> 
                  <Button icon={<Trash color="red" />} hoverIndicator onClick={ () => appOp('delete', platform.tenant, app) } />
                  <Button icon={<Info color="plain" />} hoverIndicator onClick={ () => setAlert( { title: app.title, message: app.description + ' deploying ' + app.deploy.map(a => a.name).join(', ') + '.', status: 'normal' } ) } />
                  <Button icon={<Add color="plain" />} hoverIndicator onClick={ () => appOp('apply', platform.tenant, app) } />
                  {/* <Button icon={<Test color="plain" />} hoverIndicator onClick={ () => appOp('test', platform.tenant, app) } /> */}
                </CardFooter>
              </Card>
          ))}
        </Grid>
      </Box> }
      { alert && <Notification title={ alert.title } message={ alert.message } status={ alert.status } onClose={ () => setAlert(null) } /> }
    </Box>
  );
}

export default ProjectFocus;
