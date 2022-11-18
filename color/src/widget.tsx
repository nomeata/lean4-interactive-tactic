import * as React from 'react';
import { SketchPicker } from 'react-color'

type Params = {data : string, onDataChange : (new_data  : string) => void }

export default function(props : Params) {
  return <SketchPicker
    data = { props.data }
    onChangeComplete= { (color) => {
      props.onDataChange(color.hex)
    }}
  />
}
