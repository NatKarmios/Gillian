open Containers

type outs = (Expr.t * Expr.t) list

val outs_pp : outs Fmt.t

(** The [up_step] type represents a unification plan step,
    consisting of an assertion together with the possible
    learned outs *)
type step = Asrt.t * outs [@@deriving yojson]

val step_pp : step Fmt.t

type t [@@deriving yojson]
type pred = { pred : Pred.t; def_up : t; guard_up : t option }
type 'a with_up = { up : t; data : 'a }
type spec = Spec.t with_up
type lemma = Lemma.t with_up

type 'annot prog = {
  preds : (string, pred) Hashtbl.t;
  specs : (string, spec) Hashtbl.t;
  lemmas : (string, lemma) Hashtbl.t;
  coverage : (string * int, int) Hashtbl.t;
  prog : ('annot, int) Prog.t;
}

type preds_tbl_t = (string, pred) Hashtbl.t

type up_err_t =
  | UPSpec of string * Asrt.t list list
  | UPPred of string * Asrt.t list list
  | UPLemma of string * Asrt.t list list
  | UPAssert of Asrt.t * Asrt.t list list
  | UPInvariant of Asrt.t * Asrt.t list list
[@@deriving show]

module KB = Expr.Set

val learn_expr :
  ?top_level:bool -> KB.t -> Gil_syntax.Expr.t -> Gil_syntax.Expr.t -> outs

val ins_outs_expr : KB.t -> Expr.t -> Expr.t -> (KB.t * outs) list
val collect_simple_asrts : Asrt.t -> Asrt.t list
val empty_up : t

val init :
  ?use_params:bool ->
  KB.t ->
  KB.t ->
  (string, int list) Hashtbl.t ->
  (Asrt.t * ((string * SS.t) option * (Flag.t * Asrt.t list) option)) list ->
  (t, Asrt.t list list) result

val next : t -> (t * (string * SS.t) option) list option
val head : t -> step option
val posts : t -> (Flag.t * Asrt.t list) option

val init_prog :
  ?preds_tbl:(string, pred) Hashtbl.t ->
  ('a, int) Prog.t ->
  ('a prog, up_err_t) result

val init_preds :
  (string, Pred.t) Hashtbl.t -> ((string, pred) Hashtbl.t, up_err_t) result

val pp : Format.formatter -> t -> unit
val get_pred_def : preds_tbl_t -> string -> pred
val init_pred_defs : unit -> preds_tbl_t
val pp_pred_defs : Format.formatter -> preds_tbl_t -> unit
val get_procs : 'a prog -> ('a, int) Proc.t list
val get_bispecs : 'a prog -> BiSpec.t list

val pp_asrt :
  ?preds_printer:(Format.formatter -> string * Expr.t list -> unit) ->
  preds:preds_tbl_t ->
  Format.formatter ->
  Asrt.t ->
  unit

val pp_spec :
  ?preds_printer:(Format.formatter -> string * Expr.t list -> unit) ->
  preds:preds_tbl_t ->
  Format.formatter ->
  Spec.t ->
  unit

val pp_normal_spec :
  ?preds_printer:(Format.formatter -> string * Expr.t list -> unit) ->
  preds:preds_tbl_t ->
  Format.formatter ->
  Spec.t ->
  unit

val add_spec : 'a prog -> Spec.t -> unit
val remove_spec : 'a prog -> string -> unit
val get_lemma : 'a prog -> string -> (lemma, unit) result
val update_coverage : 'a prog -> string -> int -> unit
val first_time_running : 'a prog -> string -> int -> bool
