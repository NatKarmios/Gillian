(* Create folder safely *)
let safe_mkdir path = if not (Sys.file_exists path) then Unix.mkdir path 0o777

(* Save string to file *)
let save_file path data =
  let oc = open_out path in
  output_string oc data;
  close_out oc

let save_file_pp
    (path : string)
    (pretty_printer : Format.formatter -> 'a -> unit)
    (data : 'a) =
  let oc = open_out path in
  let foc = Format.formatter_of_out_channel oc in
  pretty_printer foc data;
  Format.pp_print_flush foc ();
  close_out oc

(** Load file given his path *)
let load_file f : string =
  let ic = open_in f in
  let n = in_channel_length ic in
  let s = Bytes.create n in
  really_input ic s 0 n;
  close_in ic;
  Bytes.to_string s