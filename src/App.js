import React, { useState } from 'react';
import { Grommet, Box, Button, Text,
   Anchor, PageHeader, Paragraph, Page } from 'grommet';
import { hpe } from 'grommet-theme-hpe';
import * as Icons from 'grommet-icons';
import { HeaderWithActions } from './Header';
import Providers from './Providers';
import Settings from './Settings';
import FooterWithActions from './Footer';
import Output from './Output';
import ProjectFocus from './projectFocus';

function App() {
  const [theme, setTheme] = useState('dark');
  const [config, setConfig] = useState({});
  const [usersettings, setUsersettings] = useState({});
  const [output, setOutput] = useState([]);
  const [error, setError] = useState(undefined);
  const [provider, setProvider] = useState();
  const [logfile, setLogfile] = useState(false);
  const [spin, setSpin] = useState(false);
  const [gwurl, setGwurl] = useState(undefined);
  const [gwready, setGwready] = useState(false);
  const [prvkey, setPrvkey] = useState(false);
  const [showSettings, setShowsettings] = useState(false);
  const [stage, setStage] = useState(false);
  const [actionButton, setActionButton] = useState();
  // const [showOutput, setShowoutput] = useState(false);
  // const outputRef = useRef(undefined);
  
  const srvurl = process.env.NODE_ENV === "development" ? "http://localhost:4000" : "";
  const readyForDeployment = provider && !error && (!['runtime', 'datafabric'].includes(provider.id))
    // tricking to check valid configuration
    // TODO: need to validate configuration
    && (config['region'] !== '' || config['vcenter_server'] !== '')
  const readyForMlapps = provider && !error && ['runtime', 'datafabric'].includes(provider.id)

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
    const response = await fetchData(`${srvurl}/isfile/${provider}/run.log`);
    return response.status === 200;
  }
  
  const get_config = (target) =>
    fetchData(`${srvurl}/${target.id}/config`)
      .then(response => {
        if (!response.ok) setError(response.statusText);
        return response.json();
      }).then(
      (result) => {
        setConfig(result);
      },
      (error) => {
        console.error(error);
        setError(error.message)
      }
    );
  
  const get_usersettings = () =>
    fetchData(`${srvurl}/usersettings`)
      .then(response => {
        if (! response.ok) setError(response.statusText)
        return response.json();
      }).then(
        (result) => {
          setUsersettings(result);
        },
        (error) => {
          console.error(error);
          setError(error.message)
        }
    );
  
  const configureProvider = (target) => {
    setProvider(target);
    setSpin(false); setOutput([]); setError(null) // clear state
    if (['aws', 'azure', 'vmware'].includes(target.id)) {
      checkExistingRun(target.id).then(res => { setLogfile(res) } );
      get_config(target);
      get_usersettings();
      setShowsettings(true);
    }
  }

  const processResponse = (responseBody) => {
    setSpin(true); // start spinning
    setError(undefined); // clear up errors
    const reader = responseBody.getReader();
    return new ReadableStream({
      start(controller) {
        const reg = new RegExp('^fatal:','gm');
        function push() {
          reader.read().then( ({done, value}) => {
            if (done) {
              // finished with the stream
              controller.close();
              // setSpin(false);
              return;
            }
            controller.enqueue(value);
            const textVal = new TextDecoder().decode(value);
            // Capture fatal errors
            if (reg.test(textVal)) setError(textVal);
            if (textVal.includes('Terraform has been successfully initialized!'))
              setPrvkey(true);
            // if (textVal.includes('...ignoring')) setError(undefined);
            // Capture the gateway dns name
            if (textVal.includes('gateway_public_dns = [')) {
              setGwurl(textVal.split('gateway_public_dns = [')[1].split("'")[1]); // extract the IP
              // setTfstate(true);
            }
            // when gateway installation is complete
            if (textVal.includes('TASK [exit site lockdown]'))
              setGwready(true);
            // if External Data Fabric console ready
            if (textVal.includes('Environment destroyed'))
            {
              setPrvkey(false);
              setError(undefined);
              setSpin(false);
              controller.close();
              return;
            }
            // capture errors in output
            if (textVal.includes('Stage 4 complete')) {
              setSpin(false);
              controller.close();
              return;
            }
            
            setOutput( old => [...old, textVal] );
            // outputRef.current.scrollTop = outputRef.current.scrollHeight;
            push();
          })
        }
        setError(undefined);
        push();
      }
    });
  }

  const deploy = () => {
    setSpin(true); setStage('Deploying');
    postData(`${srvurl}/${provider.id}/deploy` )
      .then(response => {
        if (!response.ok) setError(response.statusText);
        else return response.body;
      })
      .then(rb => processResponse(rb))
      .then(stream => new Response(stream, { headers: { 'Content-Type': 'text/html' } }).text())
      .then(result => setOutput([...result]) && setActionButton(deployButton) );
  }

  const saveSettings = (settings) =>
  {
    postData(`${srvurl}/usersettings`, { usersettings: settings["usersettings"] })
      .then(response => {
        if (!response.ok) setError(response.statusText);
        else return response.body;
      })
    postData(`${srvurl}/${provider.id}/config`, { config: settings["config"] })
      .then(response => {
        if (!response.ok) setError(response.statusText);
        else return response.body;
      })
    if (readyForDeployment) {
      setActionButton(deployButton)
      setOutput([
        "Ready to deploy:", "\n",
        Object.keys(usersettings)
          .filter(key => usersettings[key] === true) // selected options
          .filter(key => key !== 'is_verbose') // discard verbose setting
          .map(selected =>
            selected.replace('is_', '').replace('install_', '').toUpperCase() // clean up
          ).join('\n')
      ]);
    }
  }

  const destroy = () => {
    setSpin(true); setStage('Destroying');
    postData(`${srvurl}/${provider.id}/destroy`)
      .then(response => response.body)
      .then(rb => processResponse(rb))
      .then(stream => new Response(stream, { headers: { 'Content-Type': 'text/html' } }).text())
      .then(result => setOutput([...result]) );
    setGwurl(undefined); setLogfile(undefined);    
  }

  const reconnectToLogs = () => {
    setOutput([]);
    fetchData(`${srvurl}/logstream/${provider.id}`)
    .then(response => response.body)
    .then(rb => processResponse(rb))
    .then(stream => new Response(stream, { headers: { 'Content-Type': 'text/html' } }).text())
    .then(result => setOutput([...result]));
    }

  const themeButton = <Button
                        tip= 'Switch Theme' key='theme'
                        icon={ theme === 'dark' ? <Icons.Moon /> : <Icons.Sun /> }
                        onClick={() => setTheme(theme === 'dark' ? 'light' : 'dark')}
                        active={ theme === 'dark' ? false : true }
  />
  const deployButton = <Button
            label={spin ? `${stage} on ${provider?.title} ...` : `Start Deployment on ${provider?.title}`}
            onClick={deploy}
            primary
            disabled={spin}
  />

  return (
    <Grommet theme={hpe} themeMode={theme} full>
      {/* Global Header */}
      <HeaderWithActions buttons={ [ themeButton ] } />
      {/* Content area */}
      <Page flex overflow='auto'>
        {/* { process.env.NODE_ENV === "development" ? "Running in development" : "" } */}
        {/* Title Content */}
        <PageHeader background="background-front"
          title="Experience Ezmeral"
          subtitle='Start your Ezmeral journey!'
          actions={
            <Box pad={{ 'horizontal': 'small' }} align='end'>
              {provider && <Text>{provider.title}</Text>}
            </Box>}
          pad={{ horizontal:'medium', top: 'small', bottom: 'large' }}
          />
        {/* Page Content */}
        <Providers params={{ provider, configureProvider }} />
        {showSettings && <Settings
          params={{ provider, config, setConfig, usersettings, setUsersettings, setShowsettings, saveSettings }} />}
        { // Connect to existing platform
          ['runtime', 'datafabric'].includes(provider?.id) && <ProjectFocus params={{ srvurl, setError, setActionButton, setSpin }} />
        }
        {/* Output Pane */}
        <Output params={{ output, spin }} />
 
        { //Deployment button
          (readyForDeployment || readyForMlapps) && actionButton
        }
        <Paragraph fill='horizontal'>
          Help is available on <Anchor href='https://youtube.com/playlist?list=PLskrf_RqaboJpWGzNkMxqc5QBUiwJ6S7x' label='Youtube' target='_blank' />
          and via your <Anchor href='https://hpe.sharepoint.com/sites/ezmeral/SitePages/Ezmeral-Champions.aspx' label=' HPE Ezmeral Champion' target='_blank' />!
        </Paragraph>
        <Box direction='row' margin="none" justify='between' border='between' gap='small' pad='small'>
          <Anchor href='https://learn.ezmeral.software.hpe.com/' label='Discover' target='_blank' />
          <Anchor href='https://hackshack.hpedev.io/workshops' label='Experience' target='_blank' />
          <Anchor href='https://www.hpe.com/demos/ezmeral' label='Show' target='_blank' />
        </Box>
      </Page>
      {/* Footer */}
      <FooterWithActions
        params={{ error, gwurl, gwready, logfile, provider, reconnectToLogs, prvkey, destroy, srvurl } }
      />
  </Grommet>
  );
}

export default App;
