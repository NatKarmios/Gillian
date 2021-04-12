open DebugProtocolEx

module Make (Debugger : Debugger.S) = struct
  let send_stopped_events stop_reason rpc =
    match stop_reason with
    | Debugger.Step | Debugger.ReachedEnd ->
        (* Send step stopped event after reaching the end to allow for stepping
           backwards *)
        Debug_rpc.send_event rpc
          (module Stopped_event)
          Stopped_event.Payload.(
            make ~reason:Stopped_event.Payload.Reason.Step ~thread_id:(Some 0)
              ())

  let run ~dbg rpc =
    Lwt.pause ();%lwt
    Debug_rpc.set_command_handler rpc
      (module Next_command)
      (fun _ ->
        let () = Log.info "Next request received" in
        let stop_reason = Debugger.step dbg in
        send_stopped_events stop_reason rpc);
    Lwt.return ()
end