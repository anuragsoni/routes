open Core
open Core_bench

let () = Command.run @@ Bench.make_command [ Static.bench ]
