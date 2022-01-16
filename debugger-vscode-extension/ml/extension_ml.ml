open Js_of_ocaml

let _ =
  Js.export_all
    (object%js
      method add x y = x +. y
      method abs x = abs_float x
      method getValFromGillian = DebugCommon.veryImportantFunction ()
     end)