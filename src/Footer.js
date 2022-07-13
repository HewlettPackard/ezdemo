import React, { Fragment } from 'react';
import {
  Anchor,
  Box,
  Button,
  Footer,
  Text,
  Tip,
} from 'grommet';
import { Multiple, StatusCritical, StatusGood, Trash } from 'grommet-icons';

export const FooterWithActions = (props) => {
  const { error, gwurl, gwready, logfile, provider, reconnectToLogs, prvkey, destroy, srvurl } = props.params;
  return(
    <Box justify='end'>
      <Footer background='brand' pad='xsmall'>
        <Fragment>
          {error ? <StatusCritical color='status-critical' /> : <StatusGood color='status-ok' />}
          {error && <Tip content={error} ><Text truncate color='red'>{error}</Text></Tip>}
          {gwurl && <Anchor label='ECP Gateway' href={'https://' + gwurl} target='_blank' rel='noreferrer' disabled={!gwready} tip={gwurl} />}
          {logfile && <Anchor label='Log' href={`${srvurl}/log/${provider.id}`} target='_blank' rel='noreferrer' />}
          {logfile && <Button label='Live Log' icon={<Multiple color='gray' />} onClick={() => reconnectToLogs()} margin='none' />}
          {prvkey && <Anchor label='PrvKey' href={`${srvurl}/key`} target='_blank' rel='noreferrer' />}
          {logfile && <Button label='Destroy' alignSelf='end'
            icon={<Trash color='status-critical' />}
            tip='Delete the environment'
            onClick={() => window.confirm('All will be deleted') && destroy()}
          />}
        </Fragment>
        <Box direction='row'>
          <Text wordBreak='keep-all' margin={{ right: 'small' }}>HPE Ezmeral @2022 </Text>
          <Anchor label='About' href='https://github.com/hewlettpackard/ezdemo' target='_blank' />
        </Box>
      </Footer>
    </Box>
  )

}

export default FooterWithActions;