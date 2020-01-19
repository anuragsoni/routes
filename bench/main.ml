open Core
open Core_bench

let () =
  let benches = List.concat [ Static.benches; Parse.benches ] in
  Command.run @@ Bench.make_command benches
