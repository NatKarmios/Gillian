type uuidm = Uuidm.t

let uuidm_to_yojson uuidm = `String (Uuidm.to_string uuidm)

let uuidm_of_yojson yojson =
  Option.to_result ~none:"uuidm should e a string"
    (match yojson with
    | `String s -> Uuidm.of_string s
    | _         -> None)

type id = int * uuidm [@@deriving yojson { exn = true }]

type severity = Info | Log | Success | Error | Warning [@@deriving yojson]

type content_type = Debug | Phase | Store [@@deriving yojson]

type t = {
  id : id;
  title : string;
  elapsed_time : float;
  previous : id option;
  parent : id option;
  content : Loggable.loggable;
  severity : severity;
  type_ : content_type;
}
[@@deriving to_yojson]
