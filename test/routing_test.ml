let idx _ () = "Matched"
let handler1 _ name age () = Printf.sprintf "%s %d" name age
let handler2 _ (_ : int) (_ : int) () = "Handler 2"
let handler3 _ (_ : int) (_ : int) () = "Handler 3"

type req = Req

let req = Req

let extract_response = function
  | Some r -> Some r
  | None -> failwith "Invalid response"
;;

let extract_none_response = function
  | None -> None
  | _ -> failwith "Expected none -> got some"
;;

let test_no_match () =
  let open Routes in
  Alcotest.(check (option string))
    "Empty routes have no match"
    None
    (extract_none_response (match' ~req ~target:"/foo/bar" ~meth:`GET []));
  Alcotest.(check (option string))
    "Empty routes with empty target"
    None
    (extract_none_response (match' ~req ~target:"" ~meth:`GET []))
;;

let test_method_match () =
  let open Routes in
  let routes = [ method' (Some `GET) (s "") ==> idx ] in
  Alcotest.(check (option string))
    "Matches handler with get method"
    (Some "Matched")
    (extract_response (match' ~req ~target:"/" ~meth:`GET routes));
  Alcotest.(check (option string))
    "Does not match if method isn't get"
    None
    (extract_none_response (match' ~req ~target:"/" ~meth:`POST routes))
;;

let test_extractors () =
  let open Routes in
  let routes = [ method' None (s "foo" </> str </> int) ==> handler1 ] in
  Alcotest.(check (option string))
    "Can extract string and int GET"
    (Some "James 11")
    (extract_response (match' ~req ~target:"/foo/James/11" ~meth:`GET routes));
  (* Since we didn't specify the method constraint it matches for `POST, `PUT etc*)
  Alcotest.(check (option string))
    "Can extract string and int"
    (Some "James 11")
    (extract_response (match' ~req ~target:"/foo/James/11" ~meth:`POST routes))
;;

let test_strict_match () =
  let open Routes in
  let route = method' None (s "foo" </> str </> int) in
  let routes = [ route ==> handler1 ] in
  (* On specifying strict match route match fails if there is unconsumed paths left *)
  Alcotest.(check (option string))
    "Non strict match"
    None
    (extract_none_response (match' ~req ~target:"foo/James/12/bar" ~meth:`GET routes))
;;

let test_route_order () =
  let open Routes in
  let routes =
    [ method' None (int </> int) ==> handler2; method' None (int </> int) ==> handler3 ]
  in
  let routes' =
    [ method' None (int </> int) ==> handler3; method' None (int </> int) ==> handler2 ]
  in
  Alcotest.(check (option string))
    "Match handler 2"
    (Some "Handler 2")
    (extract_response (match' ~req ~target:"/12/11" ~meth:`GET routes));
  Alcotest.(check (option string))
    "Match handler 3"
    (Some "Handler 3")
    (extract_response (match' ~req ~target:"/12/11" ~meth:`GET routes'))
;;

let test_printing_routes () =
  let open Routes in
  let _, route = method' None (s "user" </> str </> int) in
  let params = [ "John", 12; "James", 56; "Doe", 11 ] in
  List.iter
    (fun (u, a) ->
      Alcotest.(check string)
        "Can print out url"
        (Printf.sprintf "user/%s/%d" u a)
        ((sprintf route) u a ()))
    params
;;

(* Nested routes don't work for now *)
(* let test_nested_routes () = *)
(*   let open Routes in *)
(*   let user_handler _ name age = Printf.sprintf "%s %d" name age in *)
(*   let users state = *)
(*     let routes = [ str </> int ==> user_handler ] in *)
(*     match match_with_state ~state routes with *)
(*     | None -> "Match not found" *)
(*     | Some s -> s *)
(*   in *)
(*   let user_path = [ s "user" ==> users ] in *)
(*   Alcotest.(check (option string)) *)
(*     "Can match nested route" *)
(*     (Some "Mark 11") *)
(*     (match' ~req:Request ~target:"/user/Mark/11" ~meth:`GET user_path) *)
(* ;; *)

let tests =
  [ "Empty routes will have no matches", `Quick, test_no_match
  ; "Test method matches", `Quick, test_method_match
  ; "Test route extractors", `Quick, test_extractors
  ; "Test strict match", `Quick, test_strict_match
  ; "Test route orders", `Quick, test_route_order
  ; "Test printing routes", `Quick, test_printing_routes
    (* ; "Test nested match", `Quick, test_nested_routes *)
  ]
;;

let test_suites = [ "Routing tests", tests ]
let () = Alcotest.run "Routing tests" test_suites
