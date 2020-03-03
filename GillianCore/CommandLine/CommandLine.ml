open Cmdliner
module ParserAndCompiler = ParserAndCompiler
module L = Logging

let convert_other_imports oi =
  List.map
    (fun (ext, f) ->
      let fun_with_exn s = Stdlib.Result.get_ok (f s) in
      (ext, fun_with_exn))
    oi

module Make
    (CMemory : CMemory.S)
    (SMemory : SMemory.S)
    (External : External.S)
    (PC : ParserAndCompiler.S) (Runners : sig
      val runners : Bulk.Runner.t list
    end) =
struct
  module CState = CState.Make (CMemory)
  module CInterpreter =
    GInterpreter.Make (CVal.M) (CVal.CSubst) (CStore) (CState) (External)
  module SState = SState.Make (SMemory)
  module SInterpreter =
    GInterpreter.Make (SVal.M) (SVal.SSubst) (SStore) (SState) (External)
  module SPState =
    PState.Make (SVal.M) (SVal.SSubst) (SStore) (SState) (Preds.SPreds)
  module Verification = Verifier.Make (SState) (SPState) (External)
  module Abductor = Abductor.Make (SState) (SPState) (External)

  let file =
    let doc = "Input file." in
    let docv = "FILE" in
    Arg.(required & pos 0 (some file) None & info [] ~docv ~doc)

  let ci =
    let doc = "Indicates that the tool is being run in CI." in
    Arg.(value & flag & info [ "ci" ] ~doc)

  let already_compiled =
    let doc =
      "If you are working on already-compiled GIL files. Otherwise, the \
       compilation process will take place before analysis."
    in
    Arg.(value & flag & info [ "a"; "already-compiled" ] ~doc)

  let silent =
    let doc =
      "If you want to suppress all reporters. Improves performances a lot"
    in
    Arg.(value & flag & info [ "s"; "silent" ] ~doc)

  let output_gil =
    let doc =
      "If specified, will write into the compiled GIL program into $(docv)."
    in
    let docv = "OUTPUT" in
    Arg.(
      value & opt (some string) None & info [ "o"; "output"; "burn" ] ~doc ~docv)

  let runtime_path =
    let doc = "Specify runtime library path for imports." in
    let docv = "RUNTIME_PATH" in
    Arg.(value & opt_all string [] & info [ "R"; "runtime" ] ~doc ~docv)

  let no_heap =
    let doc = "If you want the heap output to be supressed in the logs" in
    Arg.(value & flag & info [ "no-heap" ] ~doc)

  let stats =
    let doc =
      "If you want to display statistics about the execution at the end"
    in
    Arg.(value & flag & info [ "stats" ] ~doc)

  let parallel =
    let docv = "PARALLEL" in
    let doc = "Enable parallel execution, default is false" in
    Arg.(value & flag & info [ "p"; "parallel" ] ~doc ~docv)

  let no_print_failures =
    let doc =
      "Do not print the list of all the failed tests at the end of execution \
       bulk execution"
    in
    Arg.(value & flag & info [ "no-print-all-failures" ] ~doc)

  module CompilerConsole = struct
    let mode =
      let open ExecMode in
      let doc = "Compile for Verification mode" in
      let verif =
        (Verification, Arg.info [ "ver"; "verif"; "verification" ] ~doc)
      in
      let doc = "Compile for Automatic Compositional Testing mode" in
      let act = (BiAbduction, Arg.info [ "bi"; "bi-abduction"; "act" ] ~doc) in
      let doc = "Compile for Concrete Execution mode" in
      let concrete = (Concrete, Arg.info [ "concrete"; "conc" ] ~doc) in
      let doc = "Compile for Whole Program Symbolic Testing mode" in
      let wpst =
        (Symbolic, Arg.info [ "symbolic"; "symb"; "wpst"; "stest" ] ~doc)
      in
      Arg.(last & vflag_all [ Verification ] [ concrete; wpst; verif; act ])

    let process_file file =
      let prog = Stdlib.Result.get_ok (PC.parse_and_compile_file file) in
      Io_utils.save_file_pp
        (Filename.chop_extension file ^ ".gil")
        Prog.pp_labeled prog

    let compile file mode runtime_path ci tl_opts =
      let () = Config.ci := ci in
      let () = PC.TargetLangOptions.apply tl_opts in
      let () = PC.initialize mode in
      let () = Config.current_exec_mode := mode in
      let () =
        Config.set_runtime_paths ?env_var:PC.env_var_import_path runtime_path
      in
      process_file file

    let compile_t =
      Term.(
        const compile $ file $ mode $ runtime_path $ ci
        $ PC.TargetLangOptions.term)

    let compile_info =
      let doc = "Compiles a file from the target language to GIL" in
      let man =
        [
          `S Manpage.s_description;
          `P
            "Compiles a file to GIL. Target execution mode can be specified, \
             defaults to Verification.";
        ]
      in
      Term.info "compile" ~doc ~exits:Term.default_exits ~man

    let compile_cmd = (compile_t, compile_info)
  end

  module CInterpreterConsole = struct
    let return_to_exit (ret_ok : bool) : unit =
      match ret_ok with
      | false -> exit 1
      | true  -> ()

    let valid_concrete_result (ret : CInterpreter.result_t list) : bool =
      assert (List.length ret = 1);
      let ret = List.hd ret in
      match ret with
      | ExecRes.RSucc (Flag.Normal, _, _) -> true
      | _ -> false

    let run debug (prog : ('a, int) Prog.t) : unit =
      let prog =
        match UP.init_prog prog with
        | Ok prog -> prog
        | _       -> failwith "Program could not be initialised"
      in
      let ret = CInterpreter.evaluate_prog prog in
      let () =
        if debug then
          Format.printf "Final state: @\n%a@\n" CInterpreter.pp_result ret
      in
      return_to_exit (valid_concrete_result ret)

    let exec
        file
        already_compiled
        silent
        debug
        outfile_opt
        no_heap
        runtime_paths
        ci
        tl_opts =
      let () = Config.ci := ci in
      let () = PC.TargetLangOptions.apply tl_opts in
      let () = Config.current_exec_mode := Concrete in
      let () = PC.initialize Concrete in
      Config.no_heap := no_heap;
      Logging.silent := silent;
      let () =
        Config.set_runtime_paths ?env_var:PC.env_var_import_path runtime_paths
      in
      let lab_prog =
        if not already_compiled then
          Stdlib.Result.get_ok PC.(parse_and_compile_file file)
        else Gil_parsing.parse_eprog_from_file file
      in
      let () =
        match outfile_opt with
        | Some outfile ->
            let outc = open_out outfile in
            let fmt = Format.formatter_of_out_channel outc in
            let () = Prog.pp_labeled fmt lab_prog in
            close_out outc
        | None         -> ()
      in
      let prog =
        Gil_parsing.eprog_to_prog
          ~other_imports:(convert_other_imports PC.other_imports)
          lab_prog
      in
      let () = run debug prog in
      Logging.wrap_up ()

    let debug =
      let doc =
        "If you want the final state of concrete execution to be printed at \
         the end"
      in
      Arg.(value & flag & info [ "debug"; "print-final-state" ] ~doc)

    let exec_t =
      Term.(
        const exec $ file $ already_compiled $ silent $ debug $ output_gil
        $ no_heap $ runtime_path $ ci $ PC.TargetLangOptions.term)

    let exec_info =
      let doc = "Concretely executes a file of the target language" in
      let man =
        [
          `S Manpage.s_description;
          `P "Concretely executes a given file, after compiling it to GIL";
        ]
      in
      Term.info "exec" ~doc ~exits:Term.default_exits ~man

    let exec_cmd = (exec_t, exec_info)
  end

  module SInterpreterConsole = struct
    let process_file file already_compiled outfile_opt =
      let e_prog =
        if not already_compiled then
          let _ =
            L.verbose (fun m ->
                m
                  "@\n\
                   *** Stage 1: Parsing program in original language and \
                   compiling to Gil. ***@\n")
          in
          Stdlib.Result.get_ok PC.(parse_and_compile_file file)
        else
          let _ =
            L.verbose (fun m -> m "@\n*** Stage 1: Parsing Gil program. ***@\n")
          in
          Gil_parsing.parse_eprog_from_file file
      in
      let () =
        match outfile_opt with
        | Some outfile ->
            let outc = open_out outfile in
            let fmt = Format.formatter_of_out_channel outc in
            let () = Prog.pp_labeled fmt e_prog in
            close_out outc
        | None         -> ()
      in
      let () =
        L.normal (fun m -> m "*** Stage 2: Transforming the program.\n")
      in
      let prog =
        Gil_parsing.eprog_to_prog
          ~other_imports:(convert_other_imports PC.other_imports)
          e_prog
      in
      let () =
        L.normal (fun m -> m "\n*** Stage 2: DONE transforming the program.\n")
      in
      let () = L.normal (fun m -> m "*** Stage 3: Symbolic Execution.\n") in
      match UP.init_prog prog with
      | Error _  -> failwith "Creation of unification plans failed"
      | Ok prog' ->
          let _rets : SInterpreter.result_t list =
            SInterpreter.evaluate_proc
              (fun x -> x)
              prog' "main" [] (SState.init None)
          in
          ()

    let wpst
        file
        already_compiled
        outfile_opt
        no_heap
        silent
        stats
        parallel
        runtime_path
        ci
        tl_opts =
      let () = Config.ci := ci in
      let () = PC.TargetLangOptions.apply tl_opts in
      let () = Config.current_exec_mode := Symbolic in
      let () = PC.initialize Symbolic in
      let () =
        Config.set_runtime_paths ?env_var:PC.env_var_import_path runtime_path
      in
      let () = Logging.silent := silent in
      let () = Config.stats := stats in
      let () = Config.parallel := parallel in
      let () = Config.no_heap := no_heap in
      let () = process_file file already_compiled outfile_opt in
      let () = if stats then Statistics.print_statistics () in
      let () = Logging.wrap_up () in
      try
        while true do
          let _ = Unix.wait () in
          ()
        done
      with Unix.Unix_error (Unix.ECHILD, "wait", _) -> ()

    let wpst_t =
      Term.(
        const wpst $ file $ already_compiled $ output_gil $ no_heap $ silent
        $ stats $ parallel $ runtime_path $ ci $ PC.TargetLangOptions.term)

    let wpst_info =
      let doc = "Symbolically executes a file of the target language" in
      let man =
        [
          `S Manpage.s_description;
          `P "Symbolically executes a given file, after compiling it to GIL";
        ]
      in
      Term.info "wpst" ~doc ~exits:Term.default_exits ~man

    let wpst_cmd = (wpst_t, wpst_info)
  end

  module VerificationConsole = struct
    let no_lemma_proof =
      let doc = "If you do not want to verify the proofs of lemmas" in
      Arg.(value & flag & info [ "no-lemma-proof" ] ~doc)

    let no_unfold =
      let doc = "Disables automatic unfolding of non-recursive predicates" in
      Arg.(value & flag & info [ "no-unfold" ] ~doc)

    let manual =
      let doc = "Disables automatic folding and unfolding heuristics" in
      Arg.(value & flag & info [ "m"; "manual" ] ~doc)

    let process_file file already_compiled outfile_opt no_unfold =
      let e_prog =
        if not already_compiled then
          let () =
            L.normal (fun m ->
                m
                  "@\n\
                   *** Stage 1: Parsing program in original language and \
                   compiling to Gil. ***@\n")
          in
          Stdlib.Result.get_ok PC.(parse_and_compile_file file)
        else
          let () =
            L.normal (fun m -> m "@\n*** Stage 1: Parsing Gil program. ***@\n")
          in
          Gil_parsing.parse_eprog_from_file file
      in
      let () =
        match outfile_opt with
        | Some outfile ->
            let outc = open_out outfile in
            let fmt = Format.formatter_of_out_channel outc in
            let () = Prog.pp_labeled fmt e_prog in
            close_out outc
        | None         -> ()
      in
      let () =
        L.normal (fun m -> m "@\n*** Stage 2: Transforming the program.@\n")
      in
      (* Prog.perform_syntax_checks e_prog; *)
      let prog =
        Gil_parsing.eprog_to_prog
          ~other_imports:(convert_other_imports PC.other_imports)
          e_prog
      in
      let () =
        L.verboser (fun m ->
            m "@\nProgram as parsed:@\n%a@\n" Prog.pp_indexed prog)
      in
      let () =
        L.normal (fun m ->
            m "@\n*** Stage 2: DONE transforming the program.@\n")
      in
      let () =
        L.normal (fun m -> m "@\n*** Stage 3: Logic Preprocessing.@\n")
      in
      let prog = LogicPreprocessing.preprocess prog (not no_unfold) in
      let () =
        L.verboser (fun m ->
            m "@\nProgram after logic Preprocessing:@\n%a@\n" Prog.pp_indexed
              prog)
      in
      let () =
        L.normal (fun m -> m "@\n*** Stage 3: DONE Logic Preprocessing.@\n")
      in
      let () = L.normal (fun m -> m "@\n*** Stage 4: Verification.@\n") in
      Verification.verify_procs prog

    let verify
        file
        already_compiled
        outfile_opt
        no_unfold
        stats
        no_lemma_proof
        silent
        stats
        manual
        runtime_path
        ci
        tl_opts =
      let () = Fmt_tty.setup_std_outputs () in
      let () = Config.ci := ci in
      let () = PC.TargetLangOptions.apply tl_opts in
      let () = Config.current_exec_mode := Verification in
      let () = PC.initialize Verification in
      let () = Config.stats := stats in
      let () = Logging.silent := silent in
      let () = Config.lemma_proof := not no_lemma_proof in
      let () = Config.manual_proof := manual in
      let () =
        Config.set_runtime_paths ?env_var:PC.env_var_import_path runtime_path
      in
      let () = process_file file already_compiled outfile_opt no_unfold in
      let () = if stats then Statistics.print_statistics () in
      Logging.wrap_up ()

    let verify_t =
      Term.(
        const verify $ file $ already_compiled $ output_gil $ no_unfold $ stats
        $ no_lemma_proof $ silent $ stats $ manual $ runtime_path $ ci
        $ PC.TargetLangOptions.term)

    let verify_info =
      let doc = "Verifies a file of the target language" in
      let man =
        [
          `S Manpage.s_description;
          `P "Verifies a given file, after compiling it to GIL";
        ]
      in
      Term.info "verify" ~doc ~exits:Term.default_exits ~man

    let verify_cmd = (verify_t, verify_info)
  end

  module ACTConsole = struct
    let process_file file already_compiled outfile_opt =
      let e_prog =
        if not already_compiled then
          let () =
            L.verbose (fun m ->
                m
                  "@\n\
                   *** Stage 1: Parsing program in original language and \
                   compiling to Gil. ***@\n")
          in
          Stdlib.Result.get_ok PC.(parse_and_compile_file file)
        else
          let () =
            L.verbose (fun m -> m "@\n*** Stage 1: Parsing Gil program. ***@\n")
          in
          Gil_parsing.parse_eprog_from_file file
      in
      let () =
        match outfile_opt with
        | Some outfile ->
            let outc = open_out outfile in
            let fmt = Format.formatter_of_out_channel outc in
            let () = Prog.pp_labeled fmt e_prog in
            close_out outc
        | None         -> ()
      in
      let proc_names = e_prog.proc_names in
      let () =
        L.normal (fun m -> m "*** Stage 2: Transforming the program.@\n")
      in
      let prog =
        Gil_parsing.eprog_to_prog
          ~other_imports:(convert_other_imports PC.other_imports)
          e_prog
      in
      let () =
        L.normal (fun m ->
            m "@\n*** Stage 2: DONE transforming the program.@\n")
      in
      let () = L.normal (fun m -> m "*** Stage 3: Symbolic Execution.@\n") in
      Config.unfolding := false;
      let prog = LogicPreprocessing.preprocess prog true in
      match UP.init_prog prog with
      | Error _  -> raise (Failure "Creation of unification plans failed.")
      | Ok prog' ->
          let () =
            L.(
              verboser (fun m ->
                  m "Procedure names: %a"
                    Fmt.(list ~sep:comma string)
                    proc_names))
          in
          let () = Abductor.test_procs prog' proc_names in
          if !Config.output_verification then
            let () = Prog.update_specs e_prog prog'.prog in
            let eprog_final_str = (Fmt.to_to_string Prog.pp_labeled) e_prog in
            let fname = Filename.basename file in
            let folder_path = Filename.dirname file in
            let fname' = "BI_" ^ fname in
            let path' = folder_path ^ "/" ^ fname' in
            Io_utils.save_file path' eprog_final_str

    let act
        file
        already_compiled
        outfile_opt
        no_heap
        silent
        stats
        parallel
        runtime_path
        ci
        tl_opts =
      let () = Config.ci := ci in
      let () = PC.TargetLangOptions.apply tl_opts in
      let () = Config.current_exec_mode := BiAbduction in
      let () = PC.initialize BiAbduction in
      let () = Logging.silent := silent in
      let () = Config.stats := stats in
      let () = Config.no_heap := no_heap in
      let () = Config.parallel := parallel in
      let () =
        Config.set_runtime_paths ?env_var:PC.env_var_import_path runtime_path
      in
      let () = process_file file already_compiled outfile_opt in
      let () = if !Config.stats then Statistics.print_statistics () in
      Logging.wrap_up ()

    let act_t =
      Term.(
        const act $ file $ already_compiled $ output_gil $ no_heap $ silent
        $ stats $ parallel $ runtime_path $ ci $ PC.TargetLangOptions.term)

    let act_info =
      let doc =
        "Automatic Compositional Testing of a file of the target language"
      in
      let man =
        [
          `S Manpage.s_description;
          `P
            "Uses Automatic Compositional Testing on a given file , after \
             compiling it to GIL";
        ]
      in
      Term.info "act" ~doc ~exits:Term.default_exits ~man

    let act_cmd = (act_t, act_info)
  end

  module BulkConsole = struct
    let make_bulk_console runner =
      let exec_mode = Runner.exec_mode runner in
      let path_t =
        let doc = "Path of the test suite." in
        let docv = "PATH" in
        Arg.(required & pos 0 (some file) None & info [] ~docv ~doc)
      in
      let run path tl_opts npaf runtime_path ci =
        let () = Config.ci := ci in
        let () = PC.TargetLangOptions.apply tl_opts in
        let () = Config.current_exec_mode := exec_mode in
        let () = PC.initialize exec_mode in
        let () = Config.bulk_print_all_failures := not npaf in
        Logging.silent := true;
        let () =
          Config.set_runtime_paths ?env_var:PC.env_var_import_path runtime_path
        in
        (Runner.run_all runner) path
      in
      let run_t =
        Term.(
          const run $ path_t $ PC.TargetLangOptions.term $ no_print_failures
          $ runtime_path $ ci)
      in
      let run_info =
        let doc = "Executes a predefined test-suite" in
        let man =
          [ `S Manpage.s_description; `P "Execute a predefined test-suite" ]
        in
        Term.info (Runner.cmd_name runner) ~doc ~exits:Term.default_exits ~man
      in
      (run_t, run_info)

    let bulk_cmds = List.map make_bulk_console Runners.runners
  end

  let default_cmd =
    let doc = "An analysis toolchains" in
    let sdocs = Manpage.s_common_options in
    let exits = Term.default_exits in
    let man =
      [
        `S Manpage.s_description;
        `P "Analysis toolchain for a given language, based on Gillian";
      ]
    in
    ( Term.(ret (const (fun _ -> `Help (`Pager, None)) $ const ())),
      Term.info (Filename.basename Sys.executable_name) ~doc ~sdocs ~exits ~man
    )

  let cmds =
    [
      CompilerConsole.compile_cmd;
      CInterpreterConsole.exec_cmd;
      SInterpreterConsole.wpst_cmd;
      VerificationConsole.verify_cmd;
      ACTConsole.act_cmd;
    ]
    @ BulkConsole.bulk_cmds

  let main () = Term.(exit @@ eval_choice default_cmd cmds)
end