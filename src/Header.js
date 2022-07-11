import React, { } from 'react';
import {
  Box,
  Header,
  Text,
} from 'grommet';
import {
  Hpe,
} from 'grommet-icons';

export const HeaderWithActions = (props) => (
  <Header
    border={{ color: 'border-weak', side: 'bottom' }}
    fill="horizontal"
    pad={{ horizontal: 'medium', vertical: 'small' }}
  >
    <Box
      direction="row"
      align="start"
      gap="medium"
      // pad maintains accessible hit target
      // non-responsive maintains same dimensions for mobile
      pad={{ vertical: 'small' }}
      responsive={false}
    >
      <Hpe color="brand" />
      <Box direction="row" gap="xsmall" wrap>
        <Text color="text-strong" weight="bold">
          HPE
        </Text>
        <Text color="text-strong">EzDemo</Text>
      </Box>
    </Box>
    <Box direction="row">
      { props.buttons }
    </Box>
  </Header>
);