%token EOF

(* key words *)
%token <CodeLoc.t> TRUE FALSE NULL WHILE IF ELSE SKIP NEW DELETE
%token <CodeLoc.t> FUNCTION RETURN PREDICATE LEMMA
%token <CodeLoc.t> INVARIANT FOLD UNFOLD APPLY ASSERT EXIST FORALL
%token <CodeLoc.t> STATEMENT VARIANT PROOF

(* punctuation *)
%token <CodeLoc.t> COLON            /* : */
%token <CodeLoc.t> SEMICOLON        /* ; */
%token <CodeLoc.t> COMMA            /* , */
%token <CodeLoc.t> DOT              /* . */
%token <CodeLoc.t> ASSIGN           /* := */
%token <CodeLoc.t> RCBRACE          /* } */
%token <CodeLoc.t> LCBRACE          /* { */
%token <CodeLoc.t> LBRACE           /* ( */
%token <CodeLoc.t> RBRACE           /* ) */
%token <CodeLoc.t> LBRACK           /* [ */
%token <CodeLoc.t> RBRACK           /* ] */
%token <CodeLoc.t> LOGOPEN          /* [[ */
%token <CodeLoc.t> LOGCLOSE         /* ]] */
%token <CodeLoc.t> SETOPEN          /* -{ */
%token <CodeLoc.t> SETCLOSE         /* }- */
%token <CodeLoc.t> VDASH            /* |- */

(* names *)
%token <CodeLoc.t * string> IDENTIFIER

(* values *)
%token <CodeLoc.t * int> NUMBER
%token <CodeLoc.t * string> STRING

(* Binary operators *)
%token EQUAL           /* = */
%token LESSTHAN        /* < */
%token GREATERTHAN     /* > */
%token LESSEQUAL       /* <= */
%token GREATEREQUAL    /* => */
%token PLUS            /* + */
%token MINUS           /* - */
%token TIMES           /* * */
%token DIV             /* / */
%token MOD             /* % */
%token AND             /* && */
%token OR              /* || */
%token NEQ             /* != */
%token LSTCONS         /* :: */
%token LSTCAT          /* @ */

(* Unary operators *)
%token <CodeLoc.t> NOT HEAD TAIL REV LEN

(* Logic Binary *)
%token ARROW          /* -> */
%token BLOCK_ARROW    /* -b-> */
%token LAND           /* /\ */
%token LOR            /* \/ */
%token LEQ            /* == */
%token LLESS           /* <#  */
%token LLESSEQ         /* <=# */
%token LGREATER        /* >#  */
%token LGREATEREQ      /* >=# */

(* Logic *)
%token <CodeLoc.t> EMP LTRUE LFALSE LSTNIL LNOT
%token <CodeLoc.t * string> LVAR

(* Types and start *)
%start <WProg.t> prog
%start <WLAssert.t> assert_only

%type <WFun.t list * WPred.t list * WLemma.t list> definitions
%type <WFun.t>                                     fct_with_specs
%type <WFun.t>                                     fct
%type <WPred.t>                                    predicate
%type <WLemma.t>                                   lemma
%type <string list>                                var_list
%type <WStmt.t list * WExpr.t>                     statement_list_and_return
%type <WStmt.t list>                               statement_list
%type <WExpr.t>                                    expression
%type <WExpr.t list>                               expr_list
%type <WLCmd.t>                                    logic_command
%type <WLAssert.t>                                 logic_assertion
%type <CodeLoc.t * WVal.t>                         value_with_loc
%type <CodeLoc.t * WUnOp.t>                        unop_with_loc
%type <WBinOp.t>                                   binop
%type <WExpr.t>                                    variant_def
%type <WLCmd.t list>                               proof_def
%type <string * bool>                              pred_param_ins
%type <CodeLoc.t * string list>                    bindings_with_loc
%type <WLFormula.t>                                logic_pure_formula
%type <WLExpr.t>                                   logic_expression
%type <WBinOp.t>                                   logic_binop
%type <CodeLoc.t * WVal.t>                         logic_value_with_loc
%%

prog:
  | fcp = definitions; EOF {
    let (fc, preds, lemmas) = fcp in
    WProg.{ lemmas = lemmas; predicates = preds; context = fc } }

assert_only:
  | la = logic_assertion; EOF { la }

definitions:
  | (* empty *) { ([], [], []) }
  | fpdcl = definitions; p = predicate
    { let (fs, ps,ls) = fpdcl in
      (fs, p::ps, ls) }
  | fpdcl = definitions; l = lemma
    { let (fs, ps, ls) = fpdcl in
      (fs, ps, l::ls) }
  | fpdcl = definitions; f = fct_with_specs
    { let (fs, ps, ls) = fpdcl in
      (f::fs, ps, ls) }


fct_with_specs:
  | lstart = LCBRACE; pre = logic_assertion; RCBRACE; f = fct; LCBRACE;
    post = logic_assertion; lend = RCBRACE
    { let loc = CodeLoc.merge lstart lend in
      WFun.add_spec f pre post loc }
  | f = fct { f }

fct:
  | lstart = FUNCTION; lf = IDENTIFIER; LBRACE; params = var_list; RBRACE; (* block_start = *) LCBRACE;
    stmtsandret = statement_list_and_return; lend = RCBRACE;
    { let (_, f) = lf in
      let (stmts, e) = stmtsandret in
      (* let block_loc = CodeLoc.merge block_start lend in
         let () = WStmt.check_consistency stmts block_loc in *)
      let floc = CodeLoc.merge lstart lend in
      let fid = Generators.gen_id () in
      WFun.{
        name = f;
        params = params;
        body = stmts;
        return_expr = e;
        spec = None;
        floc;
        fid;
      } }


var_list:
  lvl = separated_list(COMMA, IDENTIFIER)
  { let (_, vl) = List.split lvl (* remove locations because not needed here *)
    in vl }


statement_list_and_return:
  | RETURN; e = expression { ([], e)  }
  | sm = statement; SEMICOLON; sle = statement_list_and_return
    { let (sl, e) = sle in (sm::sl, e) }

statement_list:
  | sl = separated_nonempty_list(SEMICOLON, statement) { sl }


/* not useful at the moment */
/*
logic_cmds:
  | LCMD; lcmds = separated_list(SEMICOLON, logic_command); RCBRACE { lcmds }
 */


statement:
  | loc = SKIP { WStmt.make WStmt.Skip loc }
  | lx = IDENTIFIER; ASSIGN; e = expression
    { let (lstart, x) = lx in
      let bare_stmt = WStmt.VarAssign (x, e) in
      let lend = WExpr.get_loc e in
      let loc = CodeLoc.merge lstart lend in
      WStmt.make bare_stmt loc }
  | lx = IDENTIFIER; ASSIGN; NEW; LBRACE; ln = NUMBER; lend = RBRACE
    { let (lstart, x) = lx in
    let (_, i) = ln in
      let bare_stmt = WStmt.New (x, i) in
      let loc = CodeLoc.merge lstart lend in
      WStmt.make bare_stmt loc }
  | lstart = DELETE; LBRACE; e = expression; lend = RBRACE;
    { let bare_stmt = WStmt.Dispose e in
      let loc = CodeLoc.merge lstart lend in
      WStmt.make bare_stmt loc }
  | lx = IDENTIFIER; ASSIGN; LBRACK; e = expression; lend = RBRACK
    { let (lstart, x) = lx in
      let bare_stmt = WStmt.Lookup (x, e) in
      let loc = CodeLoc.merge lstart lend in
      WStmt.make bare_stmt loc }
  | lstart = LBRACK; e1 = expression; RBRACK; ASSIGN; e2 = expression
    {let bare_stmt = WStmt.Update (e1, e2) in
      let lend = WExpr.get_loc e2 in
      let loc = CodeLoc.merge lstart lend in
      WStmt.make bare_stmt loc
    }
  | lx = IDENTIFIER; ASSIGN; lf = IDENTIFIER; LBRACE; params = expr_list; lend = RBRACE
    { let (lstart, x) = lx in
      let (_, f) = lf in
      let bare_stmt = WStmt.FunCall (x, f, params, None) in
      let loc = CodeLoc.merge lstart lend in
      WStmt.make bare_stmt loc
    }
  | lstart = WHILE; LBRACE; b = expression; lend = RBRACE;
    (* block_start = *) LCBRACE; sl = statement_list; (* block_end = *) RCBRACE
    { (* let block_loc = CodeLoc.merge block_start block_end in
         let () = WStmt.check_consistency sl block_loc in *)
      let bare_stmt = WStmt.While (b, sl) in
      let loc = CodeLoc.merge lstart lend in
      WStmt.make bare_stmt loc
    }
  | lstart = IF; LBRACE; b = expression; lend = RBRACE;
    (* block_1_start = *) LCBRACE; sl1 = statement_list; (* block_1_end = *) RCBRACE;
    (* block_2_start = *) ELSE; LCBRACE; sl2 = statement_list; (* block_2_end = *) RCBRACE
    {
      (* let block_1_loc = CodeLoc.merge block_1_start block_1_end in
      let () = WStmt.check_consistency sl1 block_1_loc in
      let block_2_loc = CodeLoc.merge block_2_start block_2_end in
      let () = WStmt.check_consistency sl2 block_2_loc in *)
      let bare_stmt = WStmt.If (b, sl1, sl2) in
      let loc = CodeLoc.merge lstart lend in
      WStmt.make bare_stmt loc
    }
  | lstart = LOGOPEN; lc = logic_command; lend = LOGCLOSE
    { let bare_stmt = WStmt.Logic lc in
      let loc = CodeLoc.merge lstart lend in
      WStmt.make bare_stmt loc }


expr_list:
  el = separated_list(COMMA, expression) { el }

expression:
  | lstart = LBRACE; e = expression; lend = RBRACE
    { let bare_expr = WExpr.get e in
      let loc = CodeLoc.merge lstart lend in
      WExpr.make bare_expr loc }
  | lv = value_with_loc
    { let (loc, v) = lv in
      let bare_expr = WExpr.Val v in
      WExpr.make bare_expr loc }
  | lx = IDENTIFIER
    { let (loc, x) = lx in
      let bare_expr = WExpr.Var x in
      WExpr.make bare_expr loc }
  | e1 = expression; b = binop; e2 = expression
    { let bare_expr = WExpr.BinOp (e1, b, e2) in
      let lstart, lend = WExpr.get_loc e1, WExpr.get_loc e2 in
      let loc = CodeLoc.merge lstart lend in
      WExpr.make bare_expr loc }
  | lu = unop_with_loc; e = expression
    { let (lstart, u) = lu in
      let bare_expr = WExpr.UnOp (u, e) in
      let lend = WExpr.get_loc e in
      let loc = CodeLoc.merge lstart lend in
      WExpr.make bare_expr loc }

binop:
  | EQUAL        { WBinOp.EQUAL }
  | LESSTHAN     { WBinOp.LESSTHAN }
  | GREATERTHAN  { WBinOp.GREATERTHAN }
  | LESSEQUAL    { WBinOp.LESSEQUAL }
  | GREATEREQUAL { WBinOp.GREATEREQUAL }
  | PLUS         { WBinOp.PLUS }
  | MINUS        { WBinOp.MINUS }
  | TIMES        { WBinOp.TIMES }
  | DIV          { WBinOp.DIV }
  | MOD          { WBinOp.MOD }
  | AND          { WBinOp.AND }
  | OR           { WBinOp.OR }
  | NEQ          { WBinOp.NEQ}

unop_with_loc:
  | loc = NOT  { (loc, WUnOp.NOT) }
  | loc = LEN  { (loc, WUnOp.LEN) }
  | loc = HEAD { (loc, WUnOp.HEAD) }
  | loc = REV  { (loc, WUnOp.REV) }
  | loc = TAIL { (loc, WUnOp.TAIL) }

value_with_loc:
  | lf = NUMBER   { let (loc, f) = lf in (loc, WVal.Num f) }
  | ls = STRING   { let (loc, s) = ls in (loc, WVal.Str s) }
  | loc = TRUE    { (loc, WVal.Bool true) }
  | loc = FALSE   { (loc, WVal.Bool false) }
  | loc = NULL    { (loc, WVal.Null) }


(* Logic stuff *)

lemma:
  | lstart = LEMMA; lname = IDENTIFIER; LCBRACE;
      STATEMENT; COLON;
      FORALL lemma_params = var_list; DOT;
      lemma_hypothesis = logic_assertion; VDASH; lemma_conclusion = logic_assertion;
      lemma_variant = option(variant_def);
      lemma_proof = option(proof_def);
      lend = RCBRACE
      { let (_, lemma_name) = lname in
        let lemma_loc = CodeLoc.merge lstart lend in
        let lemma_id = Generators.gen_id () in
        WLemma.{
          lemma_name;
          lemma_params;
          lemma_proof;
          lemma_variant;
          lemma_hypothesis;
          lemma_conclusion;
          lemma_loc;
          lemma_id;
          } }

variant_def:
  | VARIANT; COLON; e = expression { e }

proof_def:
  | PROOF; COLON; pr = separated_nonempty_list(SEMICOLON, logic_command)
    { pr }

predicate:
  | lstart = PREDICATE; lpname = IDENTIFIER; LBRACE; params_ins = separated_list(COMMA, pred_param_ins); RBRACE; LCBRACE;
    pred_definitions = separated_nonempty_list(SEMICOLON, logic_assertion);
    lend = RCBRACE;
    { let (_, pred_name) = lpname in
      let (pred_params, ins) = List.split params_ins in
      (* ins looks like [true, false, true] *)
      let ins = List.mapi (fun i is_in -> if is_in then Some i else None) ins in
      (* ins looks like [Some 0, None, Some 2] *)
      let ins = List.filter Option.is_some ins in
      (* ins looks like [Some 0, Some 2] *)
      let ins = List.map Option.get ins in
      (* ins looks like [0, 2] *)
  		let pred_ins = if (List.length ins) > 0 then ins else (List.mapi (fun i _ -> i) pred_params) in
      (* if ins is empty then everything is an in *)
      let pred_loc = CodeLoc.merge lstart lend in
      let pred_id = Generators.gen_id () in
      WPred.{
        pred_name;
        pred_params;
        pred_definitions;
        pred_ins;
        pred_loc;
        pred_id;
      } }

pred_param_ins:
  | inp = option(PLUS); lx = IDENTIFIER
    { let (_, x) = lx in
      let isin = Option.fold ~some:(fun _ -> true) ~none:false inp in
      (x, isin) }


logic_command:
  | lstart = FOLD; lpr = IDENTIFIER;
      LBRACE; params = separated_list(COMMA, logic_expression); lend = RBRACE
    { let (_, pr) = lpr in
      let bare_lcmd = WLCmd.Fold (pr, params) in
      let loc = CodeLoc.merge lstart lend in
      WLCmd.make bare_lcmd loc }
  | lstart = UNFOLD; lpr = IDENTIFIER;
      LBRACE; params = separated_list(COMMA, logic_expression); lend = RBRACE
    { let (_, pr) = lpr in
      let bare_lcmd = WLCmd.Unfold (pr, params) in
      let loc = CodeLoc.merge lstart lend in
      WLCmd.make bare_lcmd loc }
  | lstart = APPLY; lbopt = option(bindings_with_loc); lname = IDENTIFIER; LBRACE;
    params = separated_list(COMMA, logic_expression); lend = RBRACE
    { let (_, name) = lname in
      let bindings = match lbopt with None -> [] | Some (_, bs) -> bs in
      let bare_lcmd = WLCmd.ApplyLem (name, params, bindings) in
      let loc = CodeLoc.merge lstart lend in
      WLCmd.make bare_lcmd loc }
  | lstart = IF; LBRACE; g = logic_expression; lend = RBRACE;
    LCBRACE; thencmds = separated_list(SEMICOLON, logic_command); RCBRACE;
    ELSE; LCBRACE; elsecmds = separated_list(SEMICOLON, logic_command); RCBRACE
    { let bare_lcmd = WLCmd.LogicIf (g, thencmds, elsecmds) in
      let loc = CodeLoc.merge lstart lend in
      WLCmd.make bare_lcmd loc }
  | lstart = IF; LBRACE; g = logic_expression; lend = RBRACE;
    LCBRACE; thencmds = separated_list(SEMICOLON, logic_command); RCBRACE;
    { let bare_lcmd = WLCmd.LogicIf (g, thencmds, []) in
      let loc = CodeLoc.merge lstart lend in
      WLCmd.make bare_lcmd loc }
  | lstart = ASSERT; lbopt = option(bindings_with_loc); a = logic_assertion;
    { let lend = WLAssert.get_loc a in
      let (_, b) = Option.value ~default:(lstart, []) lbopt in
      let loc = CodeLoc.merge lstart lend in
      let bare_lcmd = WLCmd.Assert (a, b) in
      WLCmd.make bare_lcmd loc }
  | lstart = INVARIANT; lbopt = option(bindings_with_loc); a = logic_assertion;
    { let lend = WLAssert.get_loc a in
      let (_, b) = Option.value ~default:(lstart, []) lbopt in
      let loc = CodeLoc.merge lstart lend in
      let bare_lcmd = WLCmd.Invariant (a, b) in
      WLCmd.make bare_lcmd loc }

bindings_with_loc:
  | lstart = LCBRACE; EXIST; COLON; lvll = separated_list(COMMA, LVAR); lend = RCBRACE;
    { let (_, lvl) = List.split lvll in
      let loc = CodeLoc.merge lstart lend in
      (loc, lvl) }


logic_assertion:
  | lstart = LBRACE; la = logic_assertion; lend = RBRACE;
    { let bare_assert = WLAssert.get la in
      let loc = CodeLoc.merge lstart lend in
      WLAssert.make bare_assert loc }
  | lpr = IDENTIFIER; LBRACE; params = separated_list(COMMA, logic_expression); lend = RBRACE
    { let (lstart, pr) = lpr in
      let bare_assert = WLAssert.LPred (pr, params) in
      let loc = CodeLoc.merge lstart lend in
      WLAssert.make bare_assert loc }
  | loc = EMP
    { let bare_assert = WLAssert.LEmp in
      WLAssert.make bare_assert loc }
  | la1 = logic_assertion; TIMES; la2 = logic_assertion
    { let bare_assert = WLAssert.LStar (la1, la2) in
      let lstart, lend = WLAssert.get_loc la1, WLAssert.get_loc la2 in
      let loc = CodeLoc.merge lstart lend in
      WLAssert.make bare_assert loc }
  | le1 = logic_expression; ARROW; le2 = separated_nonempty_list(COMMA, logic_expression)
    { let rec get_lend lel =
        match lel with
        | []  -> failwith "Nonempty list cannot be empty"
        | [a] -> WLExpr.get_loc a
        | _::r -> get_lend r
      in
      let bare_assert = WLAssert.LPointsTo (le1, le2) in
      let lstart = WLExpr.get_loc le1 in
      let lend = get_lend le2 in
      let loc = CodeLoc.merge lstart lend in
      WLAssert.make bare_assert loc }
  | le1 = logic_expression; BLOCK_ARROW; le2 = separated_nonempty_list(COMMA, logic_expression)
    { let rec get_lend lel =
        match lel with
        | []  -> failwith "Nonempty list cannot be empty"
        | [a] -> WLExpr.get_loc a
        | _::r -> get_lend r
      in
      let bare_assert = WLAssert.LBlockPointsTo (le1, le2) in
      let lstart = WLExpr.get_loc le1 in
      let lend = get_lend le2 in
      let loc = CodeLoc.merge lstart lend in
      WLAssert.make bare_assert loc }
  | formula = logic_pure_formula
    { let bare_assert = WLAssert.LPure formula in
      let loc = WLFormula.get_loc formula in
      WLAssert.make bare_assert loc }

logic_pure_formula:
  | lstart = LBRACE; la = logic_pure_formula; lend = RBRACE;
    { let loc = CodeLoc.merge lstart lend in
      let bare_form = WLFormula.get la in
      WLFormula.make bare_form loc }
  | le1 = logic_expression; LEQ; le2 = logic_expression
    { let lstart, lend = WLExpr.get_loc le1, WLExpr.get_loc le2 in
      let loc = CodeLoc.merge lstart lend in
      let bare_form = WLFormula.LEq (le1, le2) in
      WLFormula.make bare_form loc }
  | le1 = logic_expression; LLESS; le2 = logic_expression
    { let lstart, lend = WLExpr.get_loc le1, WLExpr.get_loc le2 in
      let loc = CodeLoc.merge lstart lend in
      let bare_form = WLFormula.LLess (le1, le2) in
      WLFormula.make bare_form loc }
  | le1 = logic_expression; LLESSEQ; le2 = logic_expression
    { let lstart, lend = WLExpr.get_loc le1, WLExpr.get_loc le2 in
      let loc = CodeLoc.merge lstart lend in
      let bare_form = WLFormula.LLessEq (le1, le2) in
      WLFormula.make bare_form loc }
  | le1 = logic_expression; LGREATEREQ; le2 = logic_expression
    { let lstart, lend = WLExpr.get_loc le1, WLExpr.get_loc le2 in
      let loc = CodeLoc.merge lstart lend in
      let bare_form = WLFormula.LGreaterEq (le1, le2) in
      WLFormula.make bare_form loc }
  | le1 = logic_expression; LGREATER; le2 = logic_expression
    { let lstart, lend = WLExpr.get_loc le1, WLExpr.get_loc le2 in
      let loc = CodeLoc.merge lstart lend in
      let bare_form = WLFormula.LGreater (le1, le2) in
      WLFormula.make bare_form loc }
  | lstart = LNOT; la = logic_pure_formula
    { let bare_form = WLFormula.LNot la in
      let lend = WLFormula.get_loc la in
      let loc = CodeLoc.merge lstart lend in
      WLFormula.make bare_form loc }
  | la1 = logic_pure_formula; LAND; la2 = logic_pure_formula
    { let lstart, lend = WLFormula.get_loc la1, WLFormula.get_loc la2 in
      let loc = CodeLoc.merge lstart lend in
      let bare_form = WLFormula.LAnd (la1, la2) in
      WLFormula.make bare_form loc }
  | la1 = logic_pure_formula; LOR; la2 = logic_pure_formula
    { let lstart, lend = WLFormula.get_loc la1, WLFormula.get_loc la2 in
      let loc = CodeLoc.merge lstart lend in
      let bare_form = WLFormula.LOr (la1, la2) in
      WLFormula.make bare_form loc }
  | loc = LTRUE
    { let bare_form = WLFormula.LTrue in
      WLFormula.make bare_form loc }
  | loc = LFALSE
    { let bare_form = WLFormula.LFalse in
      WLFormula.make bare_form loc }


logic_expression:
  | lstart = LBRACE; le = logic_expression; lend = RBRACE
    { let loc = CodeLoc.merge lstart lend in
      let bare_lexpr = WLExpr.get le in
      WLExpr.make bare_lexpr loc }
  | lv = logic_value_with_loc
    { let (loc, v) = lv in
      let bare_lexpr = WLExpr.LVal v in
      WLExpr.make bare_lexpr loc }
  | lx = IDENTIFIER {
    let (loc, x) = lx in
    let bare_lexpr = WLExpr.PVar x in
    WLExpr.make bare_lexpr loc }
  | llx = LVAR
    { let (loc, lx) = llx in
      let bare_lexpr = WLExpr.LVar lx in
      WLExpr.make bare_lexpr loc }
  | e1 = logic_expression; b = logic_binop; e2 = logic_expression
    { let bare_lexpr = WLExpr.LBinOp (e1, b, e2) in
      let lstart, lend = WLExpr.get_loc e1, WLExpr.get_loc e2 in
      let loc = CodeLoc.merge lstart lend in
      WLExpr.make bare_lexpr loc }
  | lu = unop_with_loc; e = logic_expression
    { let (lstart, u) = lu in
      let lend = WLExpr.get_loc e in
      let loc = CodeLoc.merge lstart lend in
      let bare_lexpr = WLExpr.LUnOp (u, e) in
      WLExpr.make bare_lexpr loc }
  | lstart = LBRACK; l = separated_list(COMMA, logic_expression); lend = RBRACK
    { let loc = CodeLoc.merge lstart lend in
      let bare_lexpr = WLExpr.LEList l in
      WLExpr.make bare_lexpr loc }
  | lstart = SETOPEN; l = separated_list(COMMA, logic_expression); lend = SETCLOSE
    { let loc = CodeLoc.merge lstart lend in
      let bare_lexpr = WLExpr.LESet l in
      WLExpr.make bare_lexpr loc }


(* We also have lists in the logic *)
logic_binop:
  | b = binop { b }
  | LSTCONS { WBinOp.LSTCONS }
  | LSTCAT { WBinOp.LSTCAT }

logic_value_with_loc:
  | lv = value_with_loc { lv }
  | loc = LSTNIL
    { (loc, WVal.VList []) }
  /* | lstart = LBRACK; lvl = separated_list(COMMA, logic_value_with_loc); lend = RBRACK
    { let (_, vl) = List.split lvl in
      let loc = CodeLoc.merge lstart lend in
      (loc, WVal.VList vl) } */