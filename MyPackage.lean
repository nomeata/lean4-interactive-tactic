import Lean
open Lean Widget

class Interactive (a : Type) where
  component : String
  /- TODO: How to signal error? -/
  fromInteractiveString : String -> a

@[widget]
def insertTextWidget : UserWidgetDefinition where
  name := "textInserter"
  javascript := include_str "widget" / "dist" / "widget.js"

structure UpdateInteractiveDataParams where
  newData : String
  range : Lsp.Range
  uri : String
  deriving FromJson, ToJson

open Server RequestM in
@[server_rpc_method]
def updateInteractiveData (params : UpdateInteractiveDataParams) : RequestM (RequestTask Int) := do
  asTask do
    Lean.Server.applyWorkspaceEdit ({
        label? := none,
        edit := .ofTextEdit params.uri { 
          newText := reprStr params.newData,
          range := params.range
        }
      }) (<- read).hOut
    return 42 /- Unit is not RPC encodable -/


open Lean Lean.Meta Lean.Elab Lean.Elab.Term in
open Elab Command in
elab "interactive" slit:str : tactic => do
  /- The type we are working at -/
  let t <- Tactic.getMainTarget

  /- The currently serialized data -/
  let data := slit.getString

  /- We solve the goal using the string and fromInteractiveString -/
  let res <- mkAppOptM `Interactive.fromInteractiveString #[some t, none, some (.lit (Literal.strVal data))]
  Tactic.closeMainGoal res

  /- Figure out the range of the strlit in LSP compatible form -/
  let r ← match Lean.Syntax.getRange? slit with
    | some r => pure r
    | none => throwUnsupportedSyntax
  let fm <- getFileMap
  /- FileWorker.EditableDocument  would be better, has version etc. -/
  let fn <- getFileName
  let lp := String.Range.toLspRange fm r


  /- We get the JS code of the widget from the Interactive instance as well -/
  let js_code_e <- whnf (<- mkAppOptM `Interactive.component #[some t, none])
  let js_code <- match js_code_e with
   | Expr.lit (Literal.strVal js_code) => pure js_code
   | _ => throwUnsupportedSyntax

  /- Now register the widget -/
  saveWidgetInfo `insertTextWidget (Json.mkObj
    [ ("range", toJson lp),
      ("uri", toJson ("file://" ++ fn)),
      ("code", toJson js_code),
      ("codeHash", toJson (hash js_code)),
      ("data", toJson data)
    ]) slit

-- Demo time!

instance : Interactive String := {
  component := "
      import * as React from 'react';
      const e = React.createElement;
      export default function(props) {
        return e('div', null,
          'You can edit the String here!',
          e('input', {
             value: props.data,
             onChange : (event) => props.onDataChange(event.target.value),
          })
        )
      }",
  fromInteractiveString := id
  }


def foo  : String := by interactive "Helosdfdh"