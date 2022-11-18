import * as React from 'react';
import { RpcContext, EditorContext } from '@leanprover/infoview';

interface Params  {
  loc : any
  data : string
  code : string
  codeHash : string
}

export default function(props : Params) {
  const editorConnection = React.useContext(EditorContext)
  const rs = React.useContext(RpcContext)

  console.log("Loading source")
  const file = new File([props.code],
      `widget_${props.codeHash}.js`, { type: 'text/javascript' })
  const url = URL.createObjectURL(file)
  console.log("Importing", file, url)
  const component = React.lazy(() => import(url))
  const subprops = {
      data: props.data,
      onDataChange: (newData : string) => {
        rs.call('updateInteractiveData', { newData, loc : props.loc})
      }
  }
  return React.createElement(component,subprops)
}
