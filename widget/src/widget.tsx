import * as React from 'react';
import { RpcContext, InteractiveCode, EditorContext } from '@leanprover/infoview';
import type { DocumentUri, Position, Range, TextDocumentPositionParams, TextEdit, WorkspaceEdit } from 'vscode-languageserver-protocol';

interface Params  {
  range : Range
  uri : string
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
        rs.call('updateInteractiveData', { newData, range: props.range, uri : props.uri})
      }
  }
  return React.createElement(component,subprops)
}
