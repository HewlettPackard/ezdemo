import React, { Fragment } from 'react';
import { Grommet, Box, Card, CardFooter, CheckBox, Button, Text, TextInput, Form, FormField, 
  Footer, Anchor, TextArea, Select, RadioButtonGroup } from 'grommet';
import { hpe } from 'grommet-theme-hpe';
import * as Icons from 'grommet-icons';
import regions from './regions';
import ProjectFocus from './projectFocus';

function App() {
  const [theme, setTheme] = React.useState('dark');
  const [output, setOutput] = React.useState([]);
  const [showoutput, setShowoutput] = React.useState(false);
  const [error, setError] = React.useState(undefined);
  const [isLoaded, setIsLoaded] = React.useState(false);
  const [provider, setProvider] = React.useState();
  const [providers, setProviders] = React.useState();
  const [config, setConfig] = React.useState({});
  const [usersettings, setUsersettings] = React.useState({});
  const [showconfig, setShowconfig] = React.useState(false);
  const [logfile, setLogfile] = React.useState(false);
  const [spin, setSpin] = React.useState(false);
  const [gwurl, setGwurl] = React.useState(undefined);
  const [gwready, setGwready] = React.useState(false);
  const [MCSready, setMCSready] = React.useState(false);
  const [prvkey, setPrvkey] = React.useState(false);
  const [projectFocus, setprojectFocus] = React.useState(false);
  const outputRef = React.useRef(undefined);
  const srvUrl = 'http://localhost:4000'
 
  React.useEffect(() => {
    const fetchData = async () => {
      fetch(`${srvUrl}/providers`)
      .then(res => res.json())
      .then(
        (result) => {
          setProviders(result);
          setIsLoaded(true);
        },
        (error) => {
          setIsLoaded(true);
          setError(error.message);
        }
      )
    };
    if (! isLoaded) fetchData();
  }, [isLoaded]);

  const fetchData = async (url) => {
    return await fetch(url, {})
  }
  
  const postData = async (url = '', data = {}) => {
    const fetchParams = {
      method: 'POST',
      headers: { 'Content-Type': 'application/json'},
      body: JSON.stringify(data)
    };
    const response = await fetch(url, fetchParams);
    return response;
  }

  const checkExistingRun = async (provider) => {
    const response = await fetchData(`${srvUrl}/isfile/${provider.toLowerCase()}/run.log`);
    return response.status === 200;
  }
  
  const configureProvider = (val) => {
    setProvider(val);
    setShowconfig(true);
    setSpin(false);
    setOutput([]); setShowoutput(false); setError(null) // clear state
    checkExistingRun(val).then(res => { setLogfile(res) } );
    fetchData(`${srvUrl}/${val.toLowerCase()}/config`)
      .then(response => {
        if (! response.ok) setError(response.statusText)
        return response.json();
      })
      .then(
        (result) => { setConfig(result); },
        (error) => { console.error(error); setError(error.message) }
      );
    fetchData(`${srvUrl}/usersettings`)
      .then(response => {
        if (! response.ok) setError(response.statusText)
        return response.json();
      })
      .then(
        (result) => { setUsersettings(result); },
        (error) => { console.error(error); setError(error.message) }
      );
  }

  const processResponse = (responseBody) => {
    setSpin(true); // start spinning
    setError(undefined); // clear up errors
    setShowconfig(false); // automatically close config form
    setShowoutput(true); // show output
    const reader = responseBody.getReader();
    return new ReadableStream({
      start(controller) {
        const reg = new RegExp('^fatal:','gm');
        function push() {
          reader.read().then( ({done, value}) => {
            if (done) {
              // finished with the stream
              controller.close();
              setSpin(false);
              return;
            }
            controller.enqueue(value);
            const textVal = new TextDecoder().decode(value);
            // Capture fatal errors
            if (reg.test(textVal)) setError(textVal);
            if (textVal.includes('...ignoring')) setError(undefined);
            // Capture the gateway dns name
            if (textVal.includes('gateway_public_dns = [')) {
              setGwurl(textVal.split('gateway_public_dns = [')[1].split("'")[1]); // extract the IP
              // setTfstate(true);
            }
            // when gateway installation is complete
            if (textVal.includes('TASK [exit site lockdown]'))
              setGwready(true);
            // if External Data Fabric console ready
            if (textVal.includes('TASK [MCS tunnel for ports]'))
              setMCSready(true);
            if (textVal.includes('Environment destroyed'))
            {
              setPrvkey(false);
              setError(undefined);
            }
            // capture errors in output
            if (textVal.includes('Terraform has been successfully initialized!'))
              setPrvkey(true);
            setOutput( old => [...old, textVal] );
            outputRef.current.scrollTop = outputRef.current.scrollHeight;
            push();
          })
        }
        setError(undefined);
        push();
      }
    });
  }

  const deploy = () => 
    postData(`${srvUrl}/${provider.toLowerCase()}/deploy`, { config, usersettings } )
    .then(response => response.body)
    .then(rb => processResponse(rb))
    .then(stream => new Response(stream, { headers: { 'Content-Type': 'text/html' } }).text())
    .then(result => setLogfile(result));

  const destroy = () =>
    postData(`${srvUrl}/${provider.toLowerCase()}/destroy`, { config, usersettings } )
    .then(response => response.body)
    .then(rb => processResponse(rb))
    .then(stream => new Response(stream, { headers: { 'Content-Type': 'text/html' } }).text())
    .then(result => { setGwurl(undefined); setLogfile(undefined); } );

  const reconnectToLogs = () => 
    fetchData(`${srvUrl}/logstream/${provider.toLowerCase()}`)
    .then(response => response.body)
    .then(rb => processResponse(rb))
    .then(stream => new Response(stream, { headers: { 'Content-Type': 'text/html' } }).text())
    .then(result => setLogfile(result));

    const reset = () => {
    // configureProvider(providers[0]);
    setProvider(null);
    setConfig({});
    setShowconfig(false);
    setOutput([]);
    setShowoutput(false);
    setGwurl(undefined);
    setMCSready(false);
    setLogfile(undefined);
    setError(undefined);
  }

  return (
    <Grommet theme={hpe} themeMode={theme} full>
      <Box fill>
        {/* Navigation Bar */}
        <Box direction='row' flex={false} justify='between'>
          <Button icon={ <Icons.Ezmeral color='brand' /> } onClick={ () => reset() } />
          {/* Providers */}
          <Box animation='zoomIn'>
            { !projectFocus && providers && <RadioButtonGroup id='target-id' 
              name='target' 
              direction='row'
              justify='evenly'
              options={ providers }
              value={ provider }
              onChange={ e => configureProvider(e.target.value) } 
            />}
          </Box>
          <Box direction='row' justify='end'>
            <CheckBox
              toggle reverse
              label={ theme === 'dark' ? <Icons.Moon /> : <Icons.Sun /> }
              checked={ theme === 'dark' ? false : true }
              onChange={ () => setTheme(theme === 'dark' ? 'light' : 'dark')}
            />
            { !projectFocus && <CheckBox 
              toggle reverse
              label={ showoutput ? <Icons.Console /> : <Icons.Desktop /> }
              checked={ showoutput ? true : false }
              onChange={ () => setShowoutput(!showoutput) }
            /> }
            { !projectFocus && <CheckBox 
              toggle reverse
              label={ showconfig ? <Icons.HostMaintenance /> : <Icons.System /> }
              checked={ showconfig ? true : false }
              onChange={ () => setShowconfig(!showconfig) }
            /> }
            { <CheckBox 
              toggle reverse
              label={ <Icons.Apps /> }
              checked={ projectFocus ? true : false }
              onChange={ () => setprojectFocus(!projectFocus) }
            /> }
          </Box>
        </Box>
        {/* Content area */}
        <Box flex overflow="auto" justify='between'>
          { projectFocus && <ProjectFocus />}
          {/* Configure */}
          { ! projectFocus && showconfig && provider &&
            <Card margin='small' flex animation='zoomIn' overflow='auto'>
              <Form
                value= { config }
                validate='change' 
                onChange= { (value) => setConfig(value) }
                >
                  { Object.keys(config).filter(k => !k.includes('region')).map( key => 
                      <FormField name={key} htmlfor={key} label={ key.toUpperCase() } key={key} margin='small'>
                        <TextInput placeholder={key} id={key} name={key} value={ config[key] } type={ key.includes('password') || key.includes('secret') || key.includes('pwd') ? 'password' : 'text' } />
                      </FormField>
                    )}
                    { (provider.toLowerCase() === 'aws' || provider.toLowerCase() === 'azure') && <FormField name='region' htmlfor='region' label='REGION' key='region' required={ true } margin='small'>
                        <Select placeholder='Region' id='region' name='region' 
                          options={regions[provider.toLowerCase()]}
                          onChange={({ option }) => setConfig( old => ( {...old, 'region': option }) )  }
                          value={ config['region'] } />
                      </FormField>
                    }
              </Form>
              <Form
                value= { usersettings }
                validate='change' 
                onChange= { (value) => setUsersettings(value) }
                >

                <CardFooter direction='column'>
                  <Box direction='row' justify='center'>
                    {
                      Object.keys(usersettings).filter(k => !k.includes('is_') && !k.includes('install_ad')).map( key => 
                        <FormField name={key} htmlfor={key} label={key.replace('is_', '').toUpperCase()} key={key} margin='small'>
                          <TextInput placeholder={key} id={key} name={key} value={ String(usersettings[key]) } type={ key.includes('password') || key.includes('secret') ? 'password' : 'text' } />
                        </FormField>
                      )
                    }
                  </Box>
                  <Box direction='row' justify='center'>
                    { Object.keys(usersettings).filter(k => k.includes('is_') || k.includes('install_ad')).map( key => 
                        <CheckBox toggle reverse key={key} label={ key.replace('is_', '').toUpperCase() } checked={ usersettings[key] } onChange={ (e) => setUsersettings( old => ( {...old, [key]: !old[key] }) ) } />
                      )
                    }
                  </Box>
                </CardFooter>
              </Form>
            </Card> }
          {/* Run */}
          { ! projectFocus && provider && (! Object.values(config).some(v => v===''))
            && <Box animation='zoomIn' direction='row' justify='between' margin='none'>
            <Button 
              label={ 'Deploy on ' + provider } 
              icon={ <Icons.Run /> } 
              onClick={ () => window.confirm('Installation will start') && deploy() } 
              margin='none' 
            />
          </Box>}

          { ! projectFocus && showoutput && 
            <Card margin='small' flex animation='zoomIn' overflow='auto'>
              <TextArea 
                readOnly 
                fill flex
                ref={ outputRef }
                value={ output.join('') }
                size='xsmall'
                plain
                style={{ whiteSpace: 'pre', fontFamily: 'Consolas,Courier New,monospace', fontSize: 'small' }} />
            </Card>
          }
        </Box>
        {/* Footer */}
        <Box flex={false} pad="none" justify='end'>
          <Footer background='brand' pad='xsmall'>
            {!projectFocus && <Fragment>
              { error ? <Icons.StatusCritical color='status-critical' /> : <Icons.StatusGood color='status-ok' /> }
              { spin && <Text color='status-warning'>Please wait...</Text> }
              { error && <Text tip={ error } color='red'>{ error.substring(0,50) }...</Text> }
              { gwurl && <Anchor label='ECP Gateway' href={ 'https://' + gwurl } target='_blank' rel='noreferrer' disabled={ !gwready } tip={ gwurl } /> }
              { config['is_mapr'] && MCSready && <Anchor label='MCS' href='https://localhost:8443' target='_blank' rel='noreferrer' disabled={ !MCSready } tip='External Data Fabric Management Console' /> }
              { config['is_mapr'] && MCSready && <Anchor label='MCS Installer' href='https://localhost:9443' target='_blank' rel='noreferrer' disabled={ !MCSready } tip='External Data Fabric Installer' /> }
              { logfile && <Anchor label='Log' href={`${srvUrl}/log/${provider.toLowerCase()}`} target='_blank' rel='noreferrer' /> }
              { logfile && <Button label='Attach to run.log' icon={ <Icons.Multiple color='gray' /> } onClick={ () => reconnectToLogs() } margin='none' /> }
              { prvkey && <Anchor label='PrvKey' href={`${srvUrl}/key`} target='_blank' rel='noreferrer' /> }
              {/* { tfstate && <Anchor label='TF State' href={`/file/${provider.toLowerCase()}/terraform.tfstate`} rel='noreferrer' /> } */}
              { logfile && <Button label='Destroy' alignSelf='end'
                icon={ <Icons.Trash color='status-critical' /> } 
                tip='Destroy the environment' 
                onClick={ () => window.confirm('All will be deleted') && destroy() } 
              /> }
            </Fragment>
            }
            <Box direction='row'>
              <Text margin={ { right: 'small' } }>HPE Ezmeral @2022 </Text>
              <Anchor label='About' onClick={ () => alert('https://github.com/hewlettpackard/ezdemo for issues and suggestions.') } />
            </Box>
          </Footer>

        </Box>
      </Box>
  </Grommet>
  );
}

export default App;
