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
  let routes = with_method [ `GET, idx <$ empty; `Other "PATCH", idx <$ empty ] in
  Alcotest.(check (option string))
    "Matches handler with patch method"
    (Some "Matched")
    (extract_response (match_with_method ~target:"/" ~meth:(`Other "PATCH") routes));
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

let test_discard_param_either_side () =
  let open Routes in
  let open Infix in
  let routes = one_of [ (fun a -> a) <$> s "foo" *> str <* s "bar" ] in
  Alcotest.(check (option string))
    "Matches empty route"
    (Some "baz")
    (match' routes "/foo/baz/bar")
;;

let test_matches_routes_with_common_prefix () =
  let open Routes in
  let open Infix in
  let routes =
    one_of [ "root" <$ empty; "one" <$ s "foo" *> s "bar"; "two" <$ s "foo" ]
  in
  Alcotest.(check (option string)) "Matches empty route" (Some "root") (match' routes "/");
  Alcotest.(check (option string))
    "Matches first overlapping path param"
    (Some "two")
    (match' routes "/foo");
  Alcotest.(check (option string))
    "Matches full path match as well"
    (Some "one")
    (match' routes "/foo/bar")
;;

let test_verify_first_parsed_route_matches () =
  let open Routes in
  let open Infix in
  (* Route `string_of_int` and `capitalize_ascii` overlap.
  But if `string_of_int` succeeds we stop there and return the result.
  Otherwise we try the remaining parsers that overlap. *)
  let routes =
    one_of
      [ "empty" <$ empty
      ; string_of_int <$> s "foo" *> int
      ; String.uppercase_ascii <$> s "foo" *> str
      ; string_of_bool <$> s "foo" *> bool
      ]
  in
  let routes' =
    one_of
      [ "empty" <$ empty
      ; (fun s -> string_of_int (String.length s)) <$> s "foo" *> str
      ; string_of_int <$> s "foo" *> int
      ; string_of_bool <$> s "foo" *> bool
      ]
  in
  Alcotest.(check (option string))
    "Matches the first route that parses successfully"
    (Some "121")
    (match' routes "/foo/121");
  Alcotest.(check (option string))
    "Matches the first route that parses successfully"
    (Some "OCAML")
    (match' routes "/foo/ocaml");
  Alcotest.(check (option string))
    "Matches the first route that parses successfully"
    (Some "3")
    (match' routes' "/foo/121")
;;

let test_leading_slash_is_discarded () =
  let open Routes in
  let open Infix in
  let routes = one_of [ "foo" <$ s "foo"; "empty" <$ empty ] in
  Alcotest.(check (option string))
    "foo with no leading slash"
    (Some "foo")
    (match' routes "foo");
  Alcotest.(check (option string))
    "foo with leading slash"
    (Some "foo")
    (match' routes "/foo");
  Alcotest.(check (option string))
    "root with leading slash"
    (Some "empty")
    (match' routes "/");
  Alcotest.(check (option string))
    "root with no leading slash"
    (Some "empty")
    (match' routes "")
;;

let convert_router_to_string_pattern_list () =
  let open Routes in
  let open Infix in
  let r1 = one_of [ "foo" <$ s "foo"; "empty" <$ empty ] in
  let meth = Alcotest.testable Method.pp Method.equal in
  let h a b c = Printf.sprintf "%d%b%ld" a b c in
  Alcotest.(check (list (pair meth  string)))
    "convert r1 to list of patterns"
    [ `GET, "foo"; `GET, "" ]
    (get_route_patterns r1);
  let routes =
    with_method
      [ `GET, "foo" <$ s "foo" <* s "bar" <* s "baz"
      ; `POST, h <$> s "user" *> int </> bool </> s "baz" *> int32
      ]
  in
  Alcotest.(check (list (pair meth  string)))
    "convert router to list of patterns"
    [ `GET,  "foo/bar/baz"; `POST,  "user/<int>/<bool>/baz/<int32>" ]
    (get_route_patterns routes)
;;

let convert_route_to_pattern () =
  let open Routes in
  let open Infix in
  let r1 = s "foo" *> s "bar" *> s "baz" in
  let h (_ : int) (_ : string) (_ : bool) (_ : int64) (_ : int32) = () in
  let r2 = h <$ s "user" </> int </> str </> s "admin" *> bool </> int64 </> s "age" *> int32 in
  Alcotest.(check string)
    "convert r1 to pattern"
    "foo/bar/baz"
    (pattern_of_route r1);
  Alcotest.(check string)
    "convert r2 to pattern"
    "user/<int>/<string>/admin/<bool>/<int64>/age/<int32>"
    (pattern_of_route r2)

let tests =
  [ "Empty routes will have no matches", `Quick, test_no_match
  ; "Method matches", `Quick, test_method_match
  ; "Route extractors", `Quick, test_extractors
  ; "Strict match", `Quick, test_strict_match
  ; "Route orders", `Quick, test_route_order
  ; "Param discards", `Quick, test_discard_param_either_side
  ; "Routes with common prefix", `Quick, test_matches_routes_with_common_prefix
  ; ( "First successful parsed route matches"
    , `Quick
    , test_verify_first_parsed_route_matches )
  ; "Leading slash is discarded", `Quick, test_leading_slash_is_discarded
  ; "Convert router to list of patterns", `Quick, convert_router_to_string_pattern_list
  ; "Convert route to pattern", `Quick, convert_route_to_pattern
  ]
;;

let test_suites =
  List.concat [ [ "Routing tests", tests ]; [ "Utilities test", Util_test.suite ] ]
;;

let () = Alcotest.run "Routing tests" test_suites
