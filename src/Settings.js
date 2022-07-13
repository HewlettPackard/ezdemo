import React, { useContext } from 'react'
import { Box, CheckBox, Form, FormField, TextInput, Select, Header, Heading, Button, ResponsiveContext } from 'grommet'
import regions from './regions';
import Modal from './Modal';

function Settings(props) {
  const { provider, config, setConfig, usersettings, setUsersettings, setShowsettings, saveSettings } = props.params;
  const size = useContext(ResponsiveContext);
  
  return (
    <Modal
      content={
        <Box
          gap="medium"
          overflow='auto'
          // Padding used to prevent focus from being cutoff
          pad={{ horizontal: 'xxsmall' }}
        >
          <Header
            direction="column"
            align="start"
            gap="xxsmall"
            pad={{ horizontal: 'xxsmall' }}
          >
            <Heading level={4} margin="none">
              {provider.title} Settings
            </Heading>
          </Header>
            <Form
              value={config}
              validate='blur'
              onChange={(value) => setConfig(value)}
              messages={{ required: 'This is a required field.' }}
            >
         { Object.keys(config)
                .filter(k => !k.includes('region'))
                  .map(key =>
              <FormField
                key={key}
                htmlfor={key}
                name={key}
                label={key.toUpperCase()}
              >
                <TextInput
                  placeholder={key}
                  id={key}
                  name={key}
                  value={config[key]}
                  type={key.includes('password') || key.includes('secret') || key.includes('pwd') ? 'password' : 'text'}
                />
              </FormField>
              )
              }
              {['aws', 'azure'].includes(provider.id) &&
                <FormField
                  key='region'
                  htmlfor='region'
                  name='region'
                  label='REGION'
                  required
                >
                  <Select
                    id='region'
                    name='region'
                    placeholder='Region'
                    options={regions[provider.id]}
                    onChange={({ option }) => setConfig(old => ({ ...old, 'region': option }))}
                    value={config['region']}
                  />
                </FormField>
              }
            </Form>

          <Header
            direction="column"
            align="start"
            gap="xxsmall"
            pad={{ horizontal: 'xxsmall' }}
          >
            <Heading level={4} margin="none">
              Deployment Settings
            </Heading>
          </Header>
          <Form
            value={usersettings}
            validate='blur'
            onChange={(value) => setUsersettings(value)}
            messages={{ required: 'This is a required field.' }}
            >
              {Object.keys(usersettings).filter(k => !k.includes('is_') && !k.includes('install_ad')).map(key =>
                <FormField
                key={key}
                name={key}
                htmlfor={key}
                label={key.toUpperCase()}
                required
                >
                  <TextInput
                    placeholder={key}
                    id={key}
                    name={key}
                    value={String(usersettings[key])}
                    type={key.includes('password') || key.includes('secret') ? 'password' : 'text'}
                  />
                </FormField>
              )
              }
              {Object.keys(usersettings).filter(k => k.includes('is_') || k.includes('install_ad')).map(key =>
                <CheckBox
                  toggle
                  key={key}
                  label={key.replace('is_', '').replace('_', ' ').toUpperCase()}
                  checked={usersettings[key]}
                  onChange={() => setUsersettings(old => ({ ...old, [key]: !old[key] }))}
                />
              )
              }
          </Form>
          <Box
            align={!['xsmall', 'small'].includes(size) ? 'start' : undefined}
            margin={{ top: 'medium', bottom: 'small' }} gap='small'
          >
            <Button label="Save" primary onClick={() => { saveSettings({ config, usersettings }); setShowsettings(false) } } />
          </Box>
        </Box>
      }
      closer={setShowsettings}
    />
  )
}

export default Settings;