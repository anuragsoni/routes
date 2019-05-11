open Core
open Core_bench

let () =
  let benches = List.concat [ [ Static.bench ]; Github.github_benches ] in
  Command.run @@ Bench.make_command benches
;;
