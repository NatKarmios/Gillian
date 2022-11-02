open Cgil_lib
module SMemory = Gillian.Monadic.MonadicSMemory.Lift (MonadicSMemory)

module Gil_to_c_lifter (Verification : Gillian.Abstraction.Verifier.S) = struct
  include
    Gillian.Debugger.Lifter.GilLifter.Make (Verification) (SMemory)
      (ParserAndCompiler)

  let add_variables = MonadicSMemory.Lift.add_variables
end

module CLI =
  Gillian.CommandLine.Make (Global_env) (CMemory) (SMemory) (External.M)
    (ParserAndCompiler)
    (struct
      let runners : Gillian.Bulk.Runner.t list =
        [ (module CRunner); (module SRunner) ]
    end)
    (Gil_to_c_lifter)

let () = CLI.main ()
