import React, { Fragment } from 'react';
import { Grommet, Box, CheckBox, Button, Text, TextInput, Form, FormField, 
  Footer, Anchor, RadioButtonGroup, TextArea } from 'grommet';
import { hpe } from "grommet-theme-hpe";
import { Home, Moon, Sun, Console, Desktop, StatusGood, StatusCritical, Run, Trash } from 'grommet-icons';

function App() {
  const [theme, setTheme] = React.useState('light');
  const [output, setOutput] = React.useState([]);
  const [showoutput, setShowoutput] = React.useState(false);
  const [error, setError] = React.useState(undefined);
  const [isLoaded, setIsLoaded] = React.useState(false);
  const [provider, setProvider] = React.useState();
  const [providers, setProviders] = React.useState();
  const [config, setConfig] = React.useState({});
  const [showconfig, setShowconfig] = React.useState(false);
  const [logfile, setLogfile] = React.useState(false);
  const [spin, setSpin] = React.useState(false);
  const [gwurl, setGwurl] = React.useState(undefined);
  const [gwready, setGwready] = React.useState(false);
  const [prvkey, setPrvkey] = React.useState(false);
  const [tfstate, setTfstate] = React.useState(false);
  const apiURL = 'http://localhost:3001';
  const outputRef = React.useRef(undefined);

  React.useEffect(() => {
    const fetchData = async () => {
      fetch(`${apiURL}/providers`)
      .then(res => res.json())
      .then(
        (result) => {
          setIsLoaded(true);
          setProviders(result);
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
  
  const postData = async (url = apiURL, data = {}) => {
    const fetchParams = {
      method: 'POST',
      headers: { 'Content-Type': 'application/json'},
      body: JSON.stringify(data)
    };
    const response = await fetch(url, fetchParams);
    return response;
  }

  const checkExistingRun = async (provider) => {
    const response = await fetchData(`${apiURL}/isfile/${provider.toLowerCase()}/run.log`);
    return response.ok;
  }
  
  const configureProvider = (val) => {
    setProvider(val);
    setShowconfig(true);
    console.dir(checkExistingRun(val));
    fetchData(`${apiURL}/${val.toLowerCase()}/config`)
      .then(response => {
        if (! response.ok) setError(response.statusText)
        return response.json();
      })
      .then(
        (result) => { setConfig(result); },
        (error) => { console.error(error); setError(error.message) }
      );
  }

  const processResponse = (responseBody) => {
    setSpin(true); // start spinning
    setError(undefined); // clear up errors
    setShowconfig(false); // automatically close config form
    setShowoutput(true); // show output
    // const gw_output_line = 'gateway_ssh_command = "ssh -o StrictHostKeyChecking=no -i ./generated/controller.prv_key centos@'
    const gw_output_line = 'gateway_public_dns = "'
    // gateway_public_dns = "ec2-35-178-92-139.eu-west-2.compute.amazonaws.com"
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
            // Capture the gateway dns name
            if (textVal.includes(gw_output_line)) {
              console.dir(textVal); // debug
              setGwurl(textVal.split('"')[1]); // extract the IP
              console.dir('set gateway url completed') // debug
              setTfstate(true);
            }
            // when gateway installation is complete
            if (textVal.includes('TASK [AD config]'))
              setGwready(true);
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
    postData(`${apiURL}/${provider.toLowerCase()}/deploy`, config)
    .then(response => response.body)
    .then(rb => processResponse(rb))
    .then(stream => new Response(stream, { headers: { "Content-Type": "text/html" } }).text())
    .then(result => setLogfile(result));

  const destroy = () =>
    postData(`${apiURL}/${provider.toLowerCase()}/destroy`, config)
    .then(response => response.body)
    .then(rb => processResponse(rb))
    .then(stream => new Response(stream, { headers: { "Content-Type": "text/html" } }).text())
    .then(result => console.dir(result) && setGwurl(undefined) );

  const log = () =>
    fetchData(`${apiURL}/${provider.toLowerCase()}/log`)
    .then(response => response.body)
    .then(rb => processResponse(rb))
    .then(stream => new Response(stream, { headers: { "Content-Type": "text/html" } }).text())
    .then(result => console.dir(result) && setGwurl(undefined) );

  const reset = () => {
    configureProvider(providers[0]);
    setOutput([]);
    setGwurl(undefined);
    setLogfile(undefined);
    setError(undefined);
  }

  return (
    <Grommet theme={hpe} themeMode={theme} full>
      <Box fill>
      {/* Navigation Bar */}
      <Box direction='row' justify='between'>
        <Button icon={ <Home /> } onClick={ () => reset() } />
        {/* Providers */}
        <Box margin='small' animation='zoomIn'>
          { providers && <RadioButtonGroup id='target-id' 
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
            label={ theme === 'dark' ? <Moon /> : <Sun /> }
            checked={ theme === 'dark' ? false : true }
            onChange={ () => setTheme(theme === 'dark' ? 'light' : 'dark')}
          />
          { output.length > 0 && <CheckBox 
            toggle reverse
            label={ showoutput ? <Console /> : <Desktop /> }
            checked={ showoutput ? true : false }
            onChange={ () => setShowoutput(!showoutput) }
          /> }
        </Box>
      </Box>
      {/* Configure */}
      <Button 
          alignSelf='end' 
          plain margin='small'
          label={ showconfig ? 'Hide config' : 'Show config' } 
          onClick={ () => setShowconfig(!showconfig) } /> 
      { showconfig && <Box animation='zoomIn'>
        <Form
          value= { config }
          validate='change' 
          onChange= { (value) => setConfig(value) }
          >
            {/* { Object.keys(config).map( key => 
                <FormField name={key} htmlfor={key} label={ key.replace('is_', '') } key={key} required={ !key.includes('is_') } margin="small">
                    { key.includes('is_') ?
                      <CheckBox toggle reverse key={key} label={key.replace('is_','')} checked={ config[key] } onChange={ (e) => setConfig( old => ( {...old, [key]: !old[key] }) ) } />
                      :
                      <TextInput placeholder={key} id={key} name={key} value={ config[key] } type={ key.includes('password') || key.includes('secret') ? 'password' : 'text' } />
                    }
                </FormField>
              )} */}
            { Object.keys(config).filter(k => !k.includes('is_')).map( key => 
                <FormField name={key} htmlfor={key} label={ key.replace('is_', '') } key={key} required={ !key.includes('is_') } margin="small">
                      <TextInput placeholder={key} id={key} name={key} value={ config[key] } type={ key.includes('password') || key.includes('secret') ? 'password' : 'text' } />
                </FormField>
              )}
              <Box direction='row' justify='center'>
                <CheckBox toggle reverse label='Verbose' checked={ config['is_verbose'] } onChange={ () => setConfig( old => ( {...old, 'is_verbose': !old['is_verbose'] }) ) } />
                <CheckBox toggle reverse label='MLOps' checked={ config['is_mlops'] } onChange={ () => setConfig( old => ( {...old, 'is_mlops': !old['is_mlops'] }) ) } />
              </Box>
          </Form>
      </Box> }
      {/* Run */}
      { provider && (! Object.values(config).some(v => v===""))
        && <Box animation='zoomIn' direction='row' justify='center' margin='none'>
        <Button 
          label={ 'Deploy on ' + provider } 
          icon={ <Run /> } 
          onClick={ () => window.confirm('Installation will start') && deploy() } 
          margin='none' 
        />
        { spin && <Text>Please wait...</Text> }
      </Box>}

      <Box pad='small' fill flex animation='zoomIn' overflow='scroll'>
        { showoutput && 
          <TextArea 
            readOnly 
            fill
            ref={ outputRef }
            value={ output.join('') }
            size='xsmall'
            plain
            style={{ whiteSpace: 'pre', fontFamily: 'Consolas,Courier New,monospace' }} />
        }
      </Box>

      {/* Debug mode */}
        { debug && <pre> Provider: { JSON.stringify(provider, undefined, 2) } </pre> }
        { debug && <pre> Config: { JSON.stringify(config, undefined, 2) } </pre>}
        { debug && <pre> Ref: { JSON.stringify(outputRef?.current?.scrollHeight, undefined, 2) } </pre>}
      {/* Footer */}
      <Box justify='end'>
        <Footer background='brand' pad='medium'>
          <Fragment>
            { error ? <StatusCritical color='status-critical' /> : <StatusGood color='status-ok' /> }
            { error && <Text color='red' tip={ error }>{ error.substr(0, 40) + '...' }</Text> }
            { gwurl && <Anchor label='ECP Gateway' href={ "https://" + gwurl } target='_blank' rel='noreferrer' disabled={ !gwready } /> }
            { logfile && <Anchor label="Logs" href={`${apiURL}/file/${provider.toLowerCase()}/run.log`} /> }
            { prvkey && <Anchor label="Private Key" href={`${apiURL}/file/generated/controller.prv_key`} /> }
            { prvkey && <Button label='Destroy'
              icon={ <Trash color="status-critical" /> } 
              tip='Destroy the environment' 
              onClick={ () => window.confirm('All will be deleted') && destroy() } 
            /> }
            { tfstate && <Anchor label="TF State" href={`${apiURL}/file/${provider.toLowerCase()}/terraform.tfstate`} /> }
          </Fragment>
          <Box direction='row'>
            <Text margin={ { right: 'small' } }>Copyright HPE @2021 </Text>
            <Anchor label='About' onClick={ () => alert('Contact Erdinc Kaya <kaya@hpe.com> for suggestions.') } />
          </Box>
        </Footer>
      </Box>
    </Box>
  </Grommet>
  );
}

export default App;
