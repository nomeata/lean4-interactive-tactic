import * as React from 'react';
import debounce from 'lodash.debounce';

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
  const [localData, setLocalData] = React.useState(props.data)

  if (! module_cache.hasOwnProperty(props.codeHash)) {
    console.log("Loading source")
    const file = new File([props.code],
        `widget_${props.codeHash}.js`, { type: 'text/javascript' })
    const url = URL.createObjectURL(file)
    console.log("Importing", file, url)
    module_cache[props.codeHash] = React.lazy(() => import(url))
  }

  const reportChange = (newData : string, loc : any) =>
      rs.call('updateInteractiveData', { newData, loc });
  const debouncedChangeHandler = React.useMemo(() => debounce(reportChange, 300), [])
  const handler = (newData : string) => {
    setLocalData(newData)
    debouncedChangeHandler(newData, props.loc)
  }

  return React.createElement(module_cache[props.codeHash],
    { data: localData, onDataChange: handler })
}
