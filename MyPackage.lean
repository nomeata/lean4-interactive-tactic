import Lean
open Lean Widget

def otherWidget : String :=  "
    import * as React from 'react';
    export default function(props) {
      const name = props.name || 'world'
      return React.createElement('p', {}, name + '!')
    }"

@[widget]
def insertTextWidget : UserWidgetDefinition where
  name := "textInserter"
  javascript := include_str "widget" / "dist" / "widget.js"

structure ReplaceTextParams where
  newText : String
  range : Lsp.Range
  uri : String
  deriving FromJson, ToJson

open Server RequestM in
@[server_rpc_method]
def replaceText (params : ReplaceTextParams) : RequestM (RequestTask Int) := do
  asTask do
    Lean.Server.applyWorkspaceEdit ({
        label? := none,
        edit := .ofTextEdit params.uri { newText := params.newText, range := params.range }
      }) (<- read).hOut
    return 42 /- Unit is not RPC encodable -/

open Lean Lean.Meta Lean.Elab Lean.Elab.Term in
open Elab Command in
syntax (name := editCmd) "#edit " term : command

open Lean Lean.Meta Lean.Elab Lean.Elab.Term in
open Elab Command in
@[command_elab editCmd] def elabEditCmd : CommandElab := fun
  | `(#edit $tm) => do
    let r ← match Lean.Syntax.getRange? tm with
      | some r => pure r
      | none => throwUnsupportedSyntax
    let fm <- getFileMap
    let fn <- getFileName
    let lp := String.Range.toLspRange fm r
    saveWidgetInfo `insertTextWidget (Json.mkObj
      [ ("range", toJson lp),
        ("uri", toJson ("file://" ++ fn)),
        ("code", toJson otherWidget),
        ("codeHash", toJson (hash otherWidget))
      ]) tm
  | _ => throwUnsupportedSyntax

#edit hello

