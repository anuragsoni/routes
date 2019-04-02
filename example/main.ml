let () =
  let h1 (req : Httpaf.Request.t) i s =
    Printf.printf "Request target : %s\n" req.target;
    Printf.printf "Received: %s - %d\n" s i;
    Httpaf.Response.create `OK
  in
  let h2 req s = Httpaf.Response.create `OK in
  let idx req = Httpaf.Response.create `Forbidden in
  let r = Httpaf.Request.create `GET "/hello/11/name" in
  let req = Routes.init r r.target r.meth in
  let routes =
    let open Routes in
    [ non_empty ==> idx
    ; method' `GET </> path "hello" </> int </> str </> non_empty ==> h1
    ; method' `POST </> str ==> h2
    ]
  in
  match Routes.route routes req with
  | None -> Printf.printf "No matches found\n"
  | Some _ -> Printf.printf "Matched\n"
;;
