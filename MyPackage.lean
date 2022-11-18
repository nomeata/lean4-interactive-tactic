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
        edit := .ofTextEdit params.uri { 
          newText := reprStr params.newText,
          range := params.range
        }
      }) (<- read).hOut
    return 42 /- Unit is not RPC encodable -/


instance : Interactive String := {
  component := "
      import * as React from 'react';
      export default function(props) {
        const name = props.name || 'world'
        return React.createElement('p', {}, name + '!')
      }",
  fromInteractiveString := id
  }

open Lean Lean.Meta Lean.Elab Lean.Elab.Term in
open Elab Command in
elab "interactive" slit:str : tactic => do
  let s := slit.getString
  let r ← match Lean.Syntax.getRange? slit with
    | some r => pure r
    | none => throwUnsupportedSyntax
  let fm <- getFileMap
  /- FileWorker.EditableDocument  would be better, has version etc. -/
  let fn <- getFileName
  let lp := String.Range.toLspRange fm r

  let t <- Tactic.getMainTarget
  let res <- mkAppOptM `Interactive.fromInteractiveString #[some t, none, some (.lit (Literal.strVal s))]
  let js_code_e <- whnf (<- mkAppOptM `Interactive.component #[some t, none])
  let js_code <- match js_code_e with
   | Expr.lit (Literal.strVal js_code) => pure js_code
   | _ => throwUnsupportedSyntax

  Tactic.closeMainGoal res

  saveWidgetInfo `insertTextWidget (Json.mkObj
    [ ("range", toJson lp),
      ("uri", toJson ("file://" ++ fn)),
      ("code", toJson js_code),
      ("codeHash", toJson (hash js_code))
    ]) slit


def foo  : String := by interactive "id"