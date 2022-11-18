import Lean
open Lean Widget

/-- The public interface: -/
class Interactive (a : Type) where
  /--
  JS source of a React module/component:
  type InnerComponent =
    React.ComponentType<{data : string, onDataChange : (new_data  : string) => void }>
  -/
  component : String
  /--
  A lean function converting a string representation to a lean value.
  TODO: How should errors be reported here?
  -/
  fromInteractiveString : String -> a

@[widget]
def insertTextWidget : UserWidgetDefinition where
  name := "textInserter"
  javascript := include_str "widget" / "dist" / "widget.js"

/- Should be opaque to the JS side -/
structure InteractiveDataLocation where
  range : Lsp.Range
  uri : String
  deriving FromJson, ToJson /- TODO: use RPC references -/

structure UpdateInteractiveDataParams where
  newData : String
  loc : InteractiveDataLocation
  deriving FromJson, ToJson

open Server RequestM in
@[server_rpc_method]
def updateInteractiveData (params : UpdateInteractiveDataParams) : RequestM (RequestTask Int) := do
  asTask do
    Lean.Server.applyWorkspaceEdit ({
        label? := none,
        edit := .ofTextEdit params.loc.uri { 
          newText := reprStr params.newData,
          range := params.loc.range
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
  let res <- mkAppOptM `Interactive.fromInteractiveString
              #[some t, none, some (.lit (Literal.strVal data))]
  Tactic.closeMainGoal res

  /- Figure out the range of the strlit in LSP compatible form -/
  let r ← match Lean.Syntax.getRange? slit with
    | some r => pure r
    | none => throwUnsupportedSyntax
  let fm <- getFileMap
  /- FileWorker.EditableDocument  would be better, has version etc. -/
  let fn <- getFileName
  let loc : InteractiveDataLocation := {
    uri := "file://" ++ fn,
    range := String.Range.toLspRange fm r
  }

  /- We get the JS code of the widget from the Interactive instance as well -/
  let js_code_e <- whnf (<- mkAppOptM `Interactive.component #[some t, none])
  let js_code <- match js_code_e with
   | Expr.lit (Literal.strVal js_code) => pure js_code
   | _ => throwUnsupportedSyntax

  /- Now register the widget -/
  saveWidgetInfo `insertTextWidget (Json.mkObj
    [ ("loc", toJson loc),
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


def a_string : String :=
  by interactive "Heskllo, Lean "

instance : Interactive Int := {
  component := "
      import * as React from 'react';
      const e = React.createElement;
      export default function(props) {
        const val = parseInt(props.data)
        return e('div', null,
          'Current value: ', val,
          e('button', {
            onClick : (event) =>
                props.onDataChange((val + 1).toString())
          }, '+'),
          e('button', {
            onClick : (event) =>
               props.onDataChange((val - 1).toString())
           }, '-')
        )
      }",
  fromInteractiveString := λ s => s.toInt?.getD 0
  }


def an_int : Int :=
  by interactive "9"

structure Color where hex : String

instance : Interactive Color := {
  component := include_str "color" / "dist" / "widget.js",
  fromInteractiveString := λ hex => { hex }
}

def a_color : Color := by interactive "#5e4090"