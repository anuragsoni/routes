open! Base
open! Stdio

let ensure_empty ~target ~msg router =
  let open Routes in
  match match' ~target router with
  | Routes.NoMatch -> printf "%s\n" msg
  | _ -> assert false
;;

let ensure_string_match ~target router =
  let open Routes in
  match match' ~target router with
  | Routes.NoMatch -> printf "%s\n" "No route matched"
  | FullMatch r -> printf "Exact match with result = %s\n" r
  | MatchWithTrailingSlash r ->
    printf
      "Not exact match, but found a matching route with a trailing slash with result = %s\n"
      r
;;

let ensure_string_match' ~target router =
  let open Routes in
  match match' ~target router with
  | Routes.NoMatch -> None
  | FullMatch r -> Some (Printf.sprintf "Exact match with result = %s" r)
  | MatchWithTrailingSlash r ->
    Some
      (Printf.sprintf
         "Not exact match, but found a matching route with a trailing slash with result \
          = %s"
         r)
;;

let%expect_test "test no match" =
  let open Routes in
  let router = one_of [] in
  ensure_empty ~target:"/foo/bar" ~msg:"No route matched" router;
  [%expect {| No route matched |}];
  ensure_empty ~target:"" ~msg:"Empty router has no match for empty target" router;
  [%expect {| Empty router has no match for empty target |}]
;;

let%expect_test "test add route" =
  let open Routes in
  let router = one_of [] in
  ensure_empty ~target:"/foo/bar" ~msg:"Empty router has no match" router;
  [%expect {| Empty router has no match |}];
  let router = add_route ((s "foo" / str /? nil) @--> fun a -> a) router in
  ensure_string_match ~target:"/foo/bar" router;
  [%expect {| Exact match with result = bar |}];
  let router =
    List.fold_left
      ~f:(fun acc r -> add_route r acc)
      ~init:(one_of [])
      [ ((s "user" / str / int /? nil)
        @--> fun name age -> Printf.sprintf "%s %d" name age)
      ; ((int / int /? nil) @--> fun a b -> Printf.sprintf "%d" (a + b))
      ]
  in
  ensure_string_match ~target:"/2/3" router;
  [%expect {| Exact match with result = 5 |}];
  ensure_string_match ~target:"/user/john/12" router;
  [%expect {| Exact match with result = john 12 |}]
;;

let%expect_test "test union of routers" =
  let open Routes in
  let union_law nb rs1 rs2 targets =
    let router_of_list routers = List.fold_right ~f:add_route routers ~init:(one_of []) in
    let router1 = router_of_list (rs1 @ rs2) in
    let router2 = union (router_of_list rs1) (router_of_list rs2) in
    let left = List.map targets ~f:(fun target -> ensure_string_match' router1 ~target) in
    let right =
      List.map targets ~f:(fun target -> ensure_string_match' router2 ~target)
    in
    let equal = List.equal (Option.equal String.equal) left right in
    printf
      "%s\n"
      (if equal
      then Printf.sprintf "Union law %d - %b" nb equal
      else Printf.sprintf "Union law %d - %b" nb equal)
  in
  let r1 = (s "foo" / int /? nil) @--> fun i -> Int.to_string i in
  let r2 = (s "bar" / int /? nil) @--> fun i -> Int.to_string i in
  let r3 = (s "foo" / int / s "bar" / int /? nil) @--> fun i j -> Int.to_string (i + j) in
  let r4 = (s "bar" / s "baz" /? nil) @--> "0" in
  let targets = [ "foo/10"; "bar/20"; "foo/10/bar/20"; "bar/baz"; "baz" ] in
  union_law 1 [ r1 ] [] targets;
  union_law 2 [] [ r1 ] targets;
  union_law 3 [ r1 ] [ r2 ] targets;
  union_law 4 [ r1; r2 ] [ r3; r4 ] targets;
  union_law 5 [ r3; r4 ] [ r1; r2 ] targets;
  [%expect
    {|
    Union law 1 - true
    Union law 2 - true
    Union law 3 - true
    Union law 4 - true
    Union law 5 - true |}]
;;

let%expect_test "test left biased union" =
  let open Routes in
  let r1 = one_of [ ((s "foo" / int /? nil) @--> fun i -> Int.to_string i) ] in
  let r2 = one_of [ ((s "foo" / int /? nil) @--> fun i -> Int.to_string (-i)) ] in
  let router = union r1 r2 in
  ensure_string_match ~target:"foo/10" router;
  [%expect {| Exact match with result = 10 |}]
;;

let%expect_test "test map" =
  let open Routes in
  let route = (s "foo" / int /? nil) @--> fun i -> i in
  let option_map_with_int_result =
    Option.map
      ~f:Int.to_string
      (match match' (one_of [ route ]) ~target:"foo/5" with
       | FullMatch x -> Some x
       | MatchWithTrailingSlash r -> Some r
       | NoMatch -> None)
  in
  let route_map =
    match match' (one_of [ map Int.to_string route ]) ~target:"foo/5" with
    | Routes.FullMatch x -> Some x
    | MatchWithTrailingSlash r -> Some r
    | NoMatch -> None
  in
  printf
    "Routes.map f === Monad.map on the result of the route match = %b\n"
    (Option.equal String.equal option_map_with_int_result route_map);
  [%expect {| Routes.map f === Monad.map on the result of the route match = true |}]
;;

let%expect_test "test extractors" =
  let open Routes in
  let router =
    one_of
      [ ((s "foo" / str /? nil) @--> fun a -> a)
      ; ((s "numbers" / int / int64 / int32 /? nil)
        @--> fun a b c -> Printf.sprintf "%d-%Ld-%ld" a b c)
      ; ((s "bar" /? wildcard) @--> fun a -> Routes.Parts.wildcard_match a)
      ; ((s "baz" / int / s "and" /? wildcard)
        @--> fun a b -> Printf.sprintf "%d-%s" a (Routes.Parts.wildcard_match b))
      ]
  in
  ensure_string_match ~target:"foo/Movie" router;
  [%expect {| Exact match with result = Movie |}];
  ensure_string_match ~target:"/numbers/1/2/3" router;
  [%expect {| Exact match with result = 1-2-3 |}];
  ensure_string_match ~target:"/bar" router;
  [%expect {| Exact match with result = |}];
  ensure_string_match ~target:"/bar/a" router;
  [%expect {| Exact match with result = /a |}];
  ensure_string_match ~target:"/bar/a/" router;
  [%expect {| Exact match with result = /a/ |}];
  ensure_string_match ~target:"/bar/a/b" router;
  [%expect {| Exact match with result = /a/b |}];
  ensure_string_match ~target:"/baz/42/and/x/y/z/" router;
  [%expect {| Exact match with result = 42-/x/y/z/ |}]
;;

let%expect_test "test leading slash is discarded" =
  let open Routes in
  let router = one_of [ (s "foo" /? nil) @--> "foo"; nil @--> "empty" ] in
  let results =
    [ ensure_string_match' ~target:"foo" router
    ; ensure_string_match' ~target:"/foo" router
    ; ensure_string_match' ~target:"/" router
    ; ensure_string_match' ~target:"" router
    ]
  in
  printf !"%{sexp: string option list}" results;
  [%expect
    {|
    (("Exact match with result = foo") ("Exact match with result = foo")
     ("Exact match with result = empty") ("Exact match with result = empty")) |}]
;;

let%expect_test "verify that first parsed route matches" =
  let open Routes in
  let routes =
    one_of
      [ nil @--> "empty"
      ; (s "foo" / int /? nil) @--> Int.to_string_hum
      ; (s "foo" / str /? nil) @--> String.uppercase
      ; (s "foo" / bool /? nil) @--> Bool.to_string
      ]
  in
  let routes' =
    one_of
      [ nil @--> "empty"
      ; ((s "foo" / str /? nil) @--> fun s -> Int.to_string_hum (String.length s))
      ; (s "foo" / int /? nil) @--> Int.to_string_hum
      ; (s "foo" / bool /? nil) @--> Bool.to_string
      ]
  in
  let results =
    [ ( "Matches the first route that parses successfully"
      , ensure_string_match' ~target:"/foo/121" routes )
    ; ( "Matches the string route since int match failed"
      , ensure_string_match' ~target:"/foo/ocaml" routes )
    ; ( "Matches the first string route and does not go to the int matcher"
      , ensure_string_match' ~target:"/foo/451" routes' )
    ]
  in
  printf !"%{sexp: (string * string option) list}\n" results;
  [%expect
    {|
    (("Matches the first route that parses successfully"
      ("Exact match with result = 121"))
     ("Matches the string route since int match failed"
      ("Exact match with result = OCAML"))
     ("Matches the first string route and does not go to the int matcher"
      ("Exact match with result = 3"))) |}]
;;

let%expect_test "match routes with a common prefix" =
  let open Routes in
  let routes =
    one_of
      [ nil @--> "root"
      ; (s "foo" / s "bar" /? nil) @--> "one"
      ; (s "foo" /? nil) @--> "two"
      ]
  in
  let results =
    [ "Matches empty route", ensure_string_match' ~target:"/" routes
    ; "Matches first overlapping path param", ensure_string_match' ~target:"/foo" routes
    ; ( "Matches first overlapping path param"
      , ensure_string_match' ~target:"/foo/bar/" routes )
    ; ( "Matches first overlapping path param"
      , ensure_string_match' ~target:"/foo/bar" routes )
    ]
  in
  printf !"%{sexp: (string * string option) list}\n" results;
  [%expect
    {|
    (("Matches empty route" ("Exact match with result = root"))
     ("Matches first overlapping path param" ("Exact match with result = two"))
     ("Matches first overlapping path param"
      ("Not exact match, but found a matching route with a trailing slash with result = one"))
     ("Matches first overlapping path param" ("Exact match with result = one"))) |}]
;;

let%expect_test "test route patterns" =
  let open Routes in
  let r1 = s "foo" / s "bar" /? nil in
  let r2 = s "foo" / int / bool /? nil in
  let r3 = s "foo" / str / bool /? nil in
  let r4 = s "baz" /? wildcard in
  let r5 = (s "hello" / s "world" /? nil) @--> "Route" in
  let results =
    [ "empty", string_of_path nil
    ; "foo_bar", string_of_path r1
    ; "foo_int_bool", string_of_path r2
    ; "sprintf foo_int_bool", sprintf r2 12 true
    ; "foo_string_bool", string_of_path r3
    ; "sprintf_string_bool", sprintf r3 "hello" false
    ; "wildcard", string_of_path r4
    ; "pretty_print_route", string_of_route r5
    ]
  in
  printf !"%{sexp: (string * string) list}\n" results;
  [%expect
    {|
    ((empty /) (foo_bar /foo/bar) (foo_int_bool /foo/:int/:bool)
     ("sprintf foo_int_bool" /foo/12/true) (foo_string_bool /foo/:string/:bool)
     (sprintf_string_bool /foo/hello/false) (wildcard /baz/:wildcard)
     (pretty_print_route /hello/world)) |}]
;;

type shape =
  | Circle
  | Square

let shape_of_string = function
  | "Circle" | "circle" -> Some Circle
  | "Square" | "square" -> Some Square
  | _ -> None
;;

let shape_to_string = function
  | Circle -> "circle"
  | Square -> "square"
;;

let%expect_test "test custom pattern" =
  let open Routes in
  let shape = pattern shape_to_string shape_of_string ":shape" in
  let shape' = custom ~serialize:shape_to_string ~parse:shape_of_string ~label:":shape" in
  let r1 () =
    (s "foo" / int / s "shape" / shape' /? nil)
    @--> fun c shape -> Printf.sprintf "%d - %s" c (shape_to_string shape)
  in
  let r2 () = s "shape" / shape / s "create" /? nil in
  let router = one_of [ r1 () ] in
  let results =
    [ ( "can match a custom pattern"
      , ensure_string_match' ~target:"/foo/12/shape/Circle" router )
    ; ( "Invalid shape does not match"
      , ensure_string_match' ~target:"/foo/12/shape/rectangle" router )
    ; "pretty print custom pattern", Some (string_of_route (r1 ()))
    ; "serialize route with custom pattern", Some (sprintf (r2 ()) Square)
    ]
  in
  printf !"%{sexp: (string * string option) list}\n" results;
  [%expect
    {|
    (("can match a custom pattern" ("Exact match with result = 12 - circle"))
     ("Invalid shape does not match" ())
     ("pretty print custom pattern" (/foo/:int/shape/:shape))
     ("serialize route with custom pattern" (/shape/square/create))) |}]
;;

let%expect_test "route matcher discards query params" =
  let open Routes in
  let routes = one_of [ ((s "foo" / str /? nil) @--> fun x -> x); nil @--> "root" ] in
  ensure_string_match ~target:"/foo/hello?baz=bar" routes;
  ensure_string_match ~target:"?baz=bar" routes;
  [%expect {|
    Exact match with result = hello
    Exact match with result = root |}]
;;

let%expect_test "test prefixing targets" =
  let open Routes in
  let add_route path1 path2 handler (routes1, routes2) =
    let routes1 = routes1 |> add_route ((path1 / path2 /? nil) @--> handler) in
    let routes2 = routes2 |> add_route ((path1 /~ (path2 /? nil)) @--> handler) in
    routes1, routes2
  in
  let check_target (routes1, routes2) target =
    let left = ensure_string_match' ~target routes1 in
    let right = ensure_string_match' ~target routes2 in
    printf
      "Router1 and Router2 provide the same result = %b\n"
      (Option.equal String.equal left right)
  in
  let routes =
    (one_of [], one_of [])
    |> add_route (s "foo") (s "bar") "10"
    |> add_route (s "foo") int (fun n -> Int.to_string_hum n)
  in
  check_target routes "foo/bar";
  check_target routes "foo/bar/10";
  check_target routes "foo/10";
  [%expect
    {|
    Router1 and Router2 provide the same result = true
    Router1 and Router2 provide the same result = true
    Router1 and Router2 provide the same result = true |}]
;;
