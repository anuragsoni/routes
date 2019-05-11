let idx = "Matched"
let handler1 name age = Printf.sprintf "%s %d" name age
let handler2 (_ : int) (_ : int) = "Handler 2"
let handler3 (_ : int) (_ : int) = "Handler 3"

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
    (extract_none_response
       (match_with_method ~target:"/foo/bar" ~meth:`GET (with_method [])));
  Alcotest.(check (option string))
    "Empty routes with empty target"
    None
    (extract_none_response (match_with_method ~target:"" ~meth:`GET (with_method [])))
;;

let test_method_match () =
  let open Routes in
  let open Infix in
  let routes = with_method [ `GET, idx <$ empty ] in
  Alcotest.(check (option string))
    "Matches handler with get method"
    (Some "Matched")
    (extract_response (match_with_method ~target:"/" ~meth:`GET routes));
  Alcotest.(check (option string))
    "Does not match if method isn't get"
    None
    (extract_none_response (match_with_method ~target:"/" ~meth:`POST routes))
;;

let test_extractors () =
  let open Routes in
  let open Infix in
  let routes = with_method [ `GET, handler1 <$> s "foo" *> str </> int ] in
  Alcotest.(check (option string))
    "Can extract string and int GET"
    (Some "James 11")
    (extract_response (match_with_method ~target:"/foo/James/11" ~meth:`GET routes));
  (* Since we specified `GET it fails to match for `POST, `PUT etc*)
  Alcotest.(check (option string))
    "Can extract string and int"
    None
    (extract_none_response (match_with_method ~target:"/foo/James/11" ~meth:`POST routes))
;;

let test_strict_match () =
  let open Routes in
  let open Infix in
  let routes = with_method [ `GET, handler1 <$> s "foo" *> str </> int ] in
  (* On specifying strict match route match fails if there is unconsumed paths left *)
  Alcotest.(check (option string))
    "Non strict match"
    None
    (extract_none_response
       (match_with_method ~target:"foo/James/12/bar" ~meth:`GET routes))
;;

let test_route_order () =
  let open Routes in
  let open Infix in
  let routes =
    with_method [ `GET, handler2 <$> int </> int; `GET, handler3 <$> int </> int ]
  in
  let routes' =
    with_method [ `GET, handler3 <$> int </> int; `GET, handler2 <$> int </> int ]
  in
  Alcotest.(check (option string))
    "Match handler 2"
    (Some "Handler 2")
    (extract_response (match_with_method ~target:"/12/11" ~meth:`GET routes));
  Alcotest.(check (option string))
    "Match handler 3"
    (Some "Handler 3")
    (extract_response (match_with_method ~target:"/12/11" ~meth:`GET routes'))
;;

let tests =
  [ "Empty routes will have no matches", `Quick, test_no_match
  ; "Test method matches", `Quick, test_method_match
  ; "Test route extractors", `Quick, test_extractors
  ; "Test strict match", `Quick, test_strict_match
  ; "Test route orders", `Quick, test_route_order
  ]
;;

let test_suites =
  List.concat [ [ "Routing tests", tests ]; [ "Utilities test", Util_test.suite ] ]
;;

let () = Alcotest.run "Routing tests" test_suites
