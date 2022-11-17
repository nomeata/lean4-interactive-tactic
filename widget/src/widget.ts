import * as React from 'react';
const e = React.createElement;
import { RpcContext, InteractiveCode, EditorContext } from '@leanprover/infoview';
import type { DocumentUri, Position, Range, TextDocumentPositionParams, TextEdit, WorkspaceEdit } from 'vscode-languageserver-protocol';

export default function(props : {range : Range}) {
  const editorConnection = React.useContext(EditorContext)
  function onClick() {
    const uri  : string = "file:///home/jojo/build/lean/origamis/MyPackage.lean"
    //editorConnection.copyToComment('hello')
    /*
    const position_params : TextDocumentPositionParams = {
      textDocument: { uri},
      position: props.pos,
    };
    */
    console.log("Clicking")
    //editorConnection.api.insertText('hello', 'here', position_params);
    const te : TextEdit = { range: props.range, newText : "hello" }
    var changes : { [_: DocumentUri]: TextEdit[] } = {}
    changes[uri] = [ te ]
    const we : WorkspaceEdit = { changes }
    console.log(we)
    // editorConnection.api.insertText('hello', 'here', position_params);
    editorConnection.api.applyEdit(we);
    console.log("Clicked")
  }
  console.log(props);
  return e('div', null, e('button', { onClick }, 'Insert'))
}
