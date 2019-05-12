let bench_routes router targets =
  let open Routes in
  List.iter (fun (m, u) -> ignore (match_with_method ~target:u ~meth:m router)) targets
;;
