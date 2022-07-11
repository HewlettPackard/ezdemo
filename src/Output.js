import React, { } from 'react'
import { TextArea } from 'grommet'

function Output(props) {
  const { output } = props.params;

  return (
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
  )
}

export default Output;