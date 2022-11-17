import Lean
open Lean Widget

@[widget]
def helloWidget : UserWidgetDefinition where
  name := "Hello"
  javascript := "
    import * as React from 'react';
    export default function(props) {
      const name = props.name || 'world'
      return React.createElement('p', {}, name + '!')
    }"

#widget helloWidget (Json.mkObj [("name", "Joachim")])


@[widget]
def insertTextWidget : UserWidgetDefinition where
  name := "textInserter"
  javascript := include_str "widget" / "dist" / "widget.js"
-- #widget insertTextWidget .null

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
    let lp := String.Range.toLspRange fm r
    saveWidgetInfo `insertTextWidget (Json.mkObj [("range", toJson lp)]) tm
  | _ => throwUnsupportedSyntax

#edit id
