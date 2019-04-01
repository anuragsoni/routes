let () =
  let h1 _r i s =
    Printf.printf "Received: %s - %d\n" s i;
    Httpaf.Response.create `OK
  in
  let r = Httpaf.Request.create `GET "/hello/12/name" in
  let split = String.split_on_char '/' r.target |> List.filter (fun x -> x <> "") in
  let req = r, split, r.meth in
  let routes =
    Routes.[ method' `GET </> path "hello" </> int </> str </> non_empty ==> h1 ]
  in
  match Routes.route routes req with
  | None -> Printf.printf "No matches found\n"
  | Some _ -> Printf.printf "Matched\n"
;;
