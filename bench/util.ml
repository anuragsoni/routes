let bench_routes router targets =
  let open Routes in
  List.map (fun (m, u) -> match_with_method ~target:u ~meth:m router) targets
;;
