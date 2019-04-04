type request = Request

type meth =
  [ `GET
  | `POST
  | `PUT
  | `PATCH
  ]

let idx _ = "Matched"
let handler1 _ name age = Printf.sprintf "%s %d" name age
let handler2 _ (_ : int) (_ : int) = "Handler 2"
let handler3 _ (_ : int) (_ : int) = "Handler 3"

let test_no_match () =
  let open Routes in
  Alcotest.(check (option string))
    "Empty routes have no match"
    None
    (match' ~req:Request ~target:"/foo/bar" ~meth:`GET []);
  Alcotest.(check (option string))
    "Empty routes with empty target"
    None
    (match' ~req:Request ~target:"" ~meth:`GET [])
;;

let test_method_match () =
  let open Routes in
  let routes = [ method' `GET </> empty ==> idx ] in
  Alcotest.(check (option string))
    "Matches handler with get method"
    (Some "Matched")
    (match' ~req:Request ~target:"/" ~meth:`GET routes);
  Alcotest.(check (option string))
    "Does not match if method isn't get"
    None
    (match' ~req:Request ~target:"/" ~meth:`POST routes)
;;

let test_extractors () =
  let open Routes in
  let routes = [ s "foo" </> str </> int </> empty ==> handler1 ] in
  Alcotest.(check (option string))
    "Can extract string and int"
    (Some "James 11")
    (match' ~req:Request ~target:"/foo/James/11" ~meth:`GET routes);
  (* Since we didn't specify the method constraint it matches for `POST, `PUT etc*)
  Alcotest.(check (option string))
    "Can extract string and int"
    (Some "James 11")
    (match' ~req:Request ~target:"/foo/James/11" ~meth:`POST routes)
;;

let test_strict_match () =
  let open Routes in
  let route = s "foo" </> str </> int in
  let routes = [ route </> empty ==> handler1 ] in
  let routes' = [ route ==> handler1 ] in
  (* when we don't specify empty it matches anything starting with path match *)
  Alcotest.(check (option string))
    "Non strict match"
    (Some "James 12")
    (match' ~req:Request ~target:"foo/James/12/bar" ~meth:`GET routes');
  (* On specifying strict match route match fails if there is unconsumed paths left *)
  Alcotest.(check (option string))
    "Non strict match"
    None
    (match' ~req:Request ~target:"foo/James/12/bar" ~meth:`GET routes)
;;

let test_route_order () =
  let open Routes in
  let routes = [ int </> int ==> handler2; int </> int ==> handler3 ] in
  let routes' = [ int </> int ==> handler3; int </> int ==> handler2 ] in
  Alcotest.(check (option string))
    "Match handler 2"
    (Some "Handler 2")
    (match' ~req:Request ~target:"/12/11" ~meth:`GET routes);
  Alcotest.(check (option string))
    "Match handler 3"
    (Some "Handler 3")
    (match' ~req:Request ~target:"/12/11" ~meth:`GET routes')
;;

let test_nested_routes () =
  let open Routes in
  let user_handler _ name age = Printf.sprintf "%s %d" name age in
  let users state =
    let routes = [ str </> int </> empty ==> user_handler ] in
    match match_with_state ~state routes with
    | None -> "Match not found"
    | Some s -> s
  in
  let user_path = [ s "user" ==> users ] in
  Alcotest.(check (option string))
    "Can match nested route"
    (Some "Mark 11")
    (match' ~req:Request ~target:"/user/Mark/11" ~meth:`GET user_path)
;;

let tests =
  [ "Empty routes will have no matches", `Quick, test_no_match
  ; "Test method matches", `Quick, test_method_match
  ; "Test route extractors", `Quick, test_extractors
  ; "Test strict match", `Quick, test_strict_match
  ; "Test route orders", `Quick, test_route_order
  ; "Test nested match", `Quick, test_nested_routes
  ]
;;

let test_suites = [ "Routing tests", tests ]
let () = Alcotest.run "Routing tests" test_suites
