import * as React from 'react';
import { RpcContext, EditorContext } from '@leanprover/infoview';

interface Params  {
  loc : any
  data : string
  code : string
  codeHash : string
}

type InnerComponent =
  React.ComponentType<{data : string, onDataChange : (new_data  : string) => void }>

var module_cache : { [hash:string] : InnerComponent; } = {}

export default function(props : Params) {
  const editorConnection = React.useContext(EditorContext)
  const rs = React.useContext(RpcContext)

  var component
  if (module_cache.hasOwnProperty(props.codeHash)) {
    component = module_cache[props.codeHash]
  } else {
    console.log("Loading source")
    const file = new File([props.code],
        `widget_${props.codeHash}.js`, { type: 'text/javascript' })
    const url = URL.createObjectURL(file)
    console.log("Importing", file, url)
    component = React.lazy(() => import(url))
    module_cache[props.codeHash] = component
  }

  const subprops = {
      data: props.data,
      onDataChange: (newData : string) => {
        rs.call('updateInteractiveData', { newData, loc : props.loc})
      }
  }
  return React.createElement(component,subprops)
}
