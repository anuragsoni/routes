let idx _ = "Matched"
let handler1 name age _ = Printf.sprintf "%s %d" name age
let handler2 (_ : int) (_ : int) _ = "Handler 2"
let handler3 (_ : int) (_ : int) _ = "Handler 3"

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
    (extract_none_response (run' ~req ~target:"/foo/bar" ~meth:`GET (choose' [])));
  Alcotest.(check (option string))
    "Empty routes with empty target"
    None
    (extract_none_response (run' ~req ~target:"" ~meth:`GET (choose' [])))
;;

let test_method_match () =
  let open Routes in
  let open Infix in
  let routes = choose' [ [`GET] , idx <$ (s "") ] in
  Alcotest.(check (option string))
    "Matches handler with get method"
    (Some "Matched")
    (extract_response (run' ~req ~target:"/" ~meth:`GET routes));
  Alcotest.(check (option string))
    "Does not match if method isn't get"
    None
    (extract_none_response (run' ~req ~target:"/" ~meth:`POST routes))
;;

let test_extractors () =
  let open Routes in
  let open Infix in
  let routes = choose' [ [], handler1 <$> s "foo" *> str </> int ] in
  Alcotest.(check (option string))
    "Can extract string and int GET"
    (Some "James 11")
    (extract_response (run' ~req ~target:"/foo/James/11" ~meth:`GET routes));
  (* Since we didn't specify the method constraint it matches for `POST, `PUT etc*)
  Alcotest.(check (option string))
    "Can extract string and int"
    (Some "James 11")
    (extract_response (run' ~req ~target:"/foo/James/11" ~meth:`POST routes))
;;

let test_strict_match () =
  let open Routes in
  let open Infix in
  let routes = choose' [[], handler1 <$> s "foo" *> str </> int ] in
  (* On specifying strict match route match fails if there is unconsumed paths left *)
  Alcotest.(check (option string))
    "Non strict match"
    None
    (extract_none_response (run' ~req ~target:"foo/James/12/bar" ~meth:`GET routes))
;;

(* let test_route_order () = *)
(*   let open Routes in *)
(*   let open Infix in *)
(*   let routes = *)
(*     choose' [ [], handler2 <$> int </> int; [], handler3 <$> int </> int ] *)
(*   in *)
(*   let routes' = *)
(*     choose' [ [], handler3 <$> int </> int; [], handler2 <$> int </> int ] *)
(*   in *)
(*   Alcotest.(check (option string)) *)
(*     "Match handler 2" *)
(*     (Some "Handler 2") *)
(*     (extract_response (run' ~req ~target:"/12/11" ~meth:`GET routes)); *)
(*   Alcotest.(check (option string)) *)
(*     "Match handler 3" *)
(*     (Some "Handler 3") *)
(*     (extract_response (run' ~req ~target:"/12/11" ~meth:`GET routes')) *)
(* ;; *)

let tests =
  [ "Empty routes will have no matches", `Quick, test_no_match
  ; "Test method matches", `Quick, test_method_match
  ; "Test route extractors", `Quick, test_extractors
  ; "Test strict match", `Quick, test_strict_match
  (* ; "Test route orders", `Quick, test_route_order *)
  ]
;;

let test_suites = [ "Routing tests", tests ]
let () = Alcotest.run "Routing tests" test_suites
