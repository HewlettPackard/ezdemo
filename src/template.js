import React from 'react'
import { Grommet, Box, Notification, Button, DataTable, Layer, Card, Select, TextInput, NameValueList, NameValuePair } from 'grommet'
import { Add, Edge, Amazon, Vmware, Connect } from 'grommet-icons'
import { hpe as theme } from 'grommet-theme-hpe'

export default () => {
  const [layer, setLayer] = React.useState()
  return (
    <Grommet full theme={theme}>
      <Box fill overflow="auto" align="stretch" flex elevation="xsmall">
        <Notification message="This UI is under development, things may work!" status="critical" title="Experimental Features" toast global />
        <Button label="New Project" icon={<Add />} plain />
        <DataTable
          columns={[
            {header: "Project", property: "folder", primary: true},
            {header: "Environment", property: "target"}]}
           data={[{"folder":"Test1","target":"aws"},{"folder":"Test2","target":"azure"}]} sortable size="small" onSelect select="selectthis()" paginate />
        <Box align="start" justify="start" fill margin="small" elevation="xsmall">
          <Button label="Login" />
          {layer === 16 && (
          <Layer animate modal onClickOutside="hide" plain={false}>
            <Card>
              <Select options={["AWS","Azure","vCenter","oVirt"]} closeOnChange placeholder="Select provider" />
              <Select options={["option 1","option 2"]} placeholder="Select region" icon={<Edge />} />
              <Select options={["option 1","option 2"]} icon={<Amazon />} placeholder="Select region" />
              <TextInput icon={<Edge />} />
              <TextInput icon={<Edge />} />
              <TextInput icon={<Edge />} />
              <TextInput icon={<Edge />} />
              <TextInput icon={<Amazon />} />
              <TextInput icon={<Amazon />} />
              <TextInput icon={<Vmware />} />
              <TextInput icon={<Vmware />} />
              <TextInput icon={<Vmware />} />
              <Button label="Connect" icon={<Connect />} />
            </Card>
          </Layer>
      )}
          {layer === 32 && (
          <Layer animate modal>
            <NameValueList layout="column">
              <NameValuePair name="gpu" />
              <NameValuePair name="mapr" />
            </NameValueList>
          </Layer>
      )}
        </Box>
      </Box>
    </Grommet>
  )
}
