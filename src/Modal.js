import React, { useContext } from 'react'
import { Button, Layer, ResponsiveContext } from 'grommet'
import { FormClose } from 'grommet-icons'

function Modal(props) {
  const { content, closer } = props;
  const size = useContext(ResponsiveContext);

  return (
    <Layer
      position="right"
      animate
      full={!['xsmall'].includes(size) ? 'vertical' : true}
      modal
      onClickOutside={() => closer(false)}
      onEsc={ () => closer(false)}
    >
      <Button
        a11yTitle={`You are on a Close button in a layer containing
        a text description. To close the layer 
        and return to the primary content, press Enter.`}
        autoFocus
        icon={<FormClose />}
        onClick={ () => closer(false)}
      />
      { content }
    </Layer>
  )
}

export default Modal;