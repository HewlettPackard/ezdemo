import React, { useContext } from 'react'
import { Button, Grid, ResponsiveContext } from 'grommet'
import { Amazon, Ezmeral, Hadoop, Redhat, Vmware, Windows } from 'grommet-icons'

function Providers(props) {
  const breakpoint = useContext(ResponsiveContext);
  const providers = [
    {
      id: "aws",
      title: "Amazon Web Services",
      icon: <Amazon size="large" color="plain" />,
      subtitle: '',
      disabled: false,
    },
    {
      id: "azure",
      title: "Microsoft Azure",
      icon: <Windows size="large" color="plain"/>,
      subtitle: '',
      disabled: false,
    },
    {
      id: "vmware",
      title: "VMWare vCenter",
      icon: <Vmware size="large" color="plain" />,
      subtitle: '',
      disabled: false,
    },
    {
      id: "ovirt",
      title: "oVirt KVM",
      icon: <Redhat size="large" color="plain" />,
      subtitle: '',
      disabled: true,
    },
    {
      id: "runtime",
      title: "Ezmeral Runtime",
      icon: <Ezmeral size="medium" color="plain" />,
      subtitle: 'Use existing Ezmeral Platform',
      disabled: false,
    },
    {
      id: "datafabric",
      title: "Ezmeral Data Fabric",
      icon: <Hadoop size="large" color="plain" />,
      subtitle: 'Use existing Ezmeral Data Fabric',
      disabled: true,
    },
  ];

  const appGrid = {
    columns: {
      xsmall: 'auto',
      small: ['auto', 'auto'],
      medium: { count: 'fit', size: ['1/2', 'auto'] },
      large: { count: 'fit', size: ['1/3', 'auto'] },
      xlarge: { count: 'fit', size: ['1/4', 'auto'] },
    },
    rows: 'xsmall',
    gap: {
      xsmall: 'medium',
      small: 'small',
      medium: 'small',
      large: 'medium',
      xlarge: 'medium',
    },
  };
  const { provider, configureProvider } = props.params;

  return (
    <Grid
      columns={appGrid.columns[breakpoint]}
      rows={appGrid.rows}
      gap={appGrid.gap[breakpoint]}
    >
    {providers.map(app => (
      <Button
        key={app.id}
        disabled={app.disabled}
        gap='medium' margin='small'
        tip={ app.disabled ? 'Coming soon...' : app.subtitle }
        onClick={() => configureProvider(app)}
        active={provider?.id === app.id}
        icon={app.icon}
        label={app.title}
      />
      ))
      }
    </Grid>
  )
}

export default Providers;