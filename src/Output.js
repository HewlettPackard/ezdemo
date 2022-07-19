import React, { } from 'react'
import { Spinner, Stack, TextArea } from 'grommet'

function Output(props) {
  const { output, spin } = props.params;

  return (
    <Stack anchor='top-right'>
      <TextArea
        readOnly 
        fill
        resize
        rows={12}
        // ref={ outputRef }
        value={ output.join('') }
        size='xsmall'
        plain
        style={{ whiteSpace: 'pre', fontFamily: 'Consolas,Courier New,monospace', fontSize: 'small' }}
        />
      {spin && <Spinner
        size="medium"
        gap='small'
        message={{ start: 'Wait while installing.', end: 'Install complete.' }} />}
    </Stack>
  )
}

export default Output;