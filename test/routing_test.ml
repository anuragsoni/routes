let test_no_match () =
  let open Routes in
  Alcotest.(check (option string))
    "Empty router has no match"
    None
    (match' ~target:"/foo/bar" (one_of []));
  Alcotest.(check (option string))
    "Empty router has no match for empty target"
    None
    (match' ~target:"" (one_of []))
;;

let test_add_route () =
  let open Routes in
  let router = one_of [] in
  Alcotest.(check (option string))
    "Empty router has no match"
    None
    (match' ~target:"/foo/bar" router);
  Alcotest.(check (option string))
    "Can add a route"
    (Some "bar")
    (match'
       ~target:"/foo/bar"
       (add_route ((s "foo" / str /? nil) @--> fun a -> a) router));
  let router =
    List.fold_left
      (fun acc r -> add_route r acc)
      (Routes.one_of [])
      [ ((s "user" / str / int /? nil)
        @--> fun name age -> Printf.sprintf "%s %d" name age)
      ; ((int / int /? nil) @--> fun a b -> Printf.sprintf "%d" (a + b))
      ]
  in
  Alcotest.(check (option string))
    "Adding a list of routes works as well"
    (Some "5")
    (match' router ~target:"/2/3");
  Alcotest.(check (option string))
    "Adding a list of routes works as well"
    (Some "john 12")
    (match' router ~target:"/user/john/12")
;;

let test_union_routes () =
  let open Routes in
  let union_law nb t rs1 rs2 targets =
    let router_of_list routers = List.fold_right add_route routers (one_of []) in
    let router1 = router_of_list (rs1 @ rs2) in
    let router2 = union (router_of_list rs1) (router_of_list rs2) in
    Alcotest.(check (list (option t)))
      (Printf.sprintf "union law %d" nb)
      (List.map (fun target -> match' router1 ~target) targets)
      (List.map (fun target -> match' router2 ~target) targets)
  in
  let r1 = (s "foo" / int /? nil) @--> fun i -> i in
  let r2 = (s "bar" / int /? nil) @--> fun i -> i in
  let r3 = (s "foo" / int / s "bar" / int /? nil) @--> fun i j -> i + j in
  let r4 = (s "bar" / s "baz" /? nil) @--> 0 in
  let targets = [ "foo/10"; "bar/20"; "foo/10/bar/20"; "bar/baz"; "baz" ] in
  union_law 1 Alcotest.int [ r1 ] [] targets;
  union_law 2 Alcotest.int [] [ r1 ] targets;
  union_law 3 Alcotest.int [ r1 ] [ r2 ] targets;
  union_law 4 Alcotest.int [ r1; r2 ] [ r3; r4 ] targets;
  union_law 5 Alcotest.int [ r3; r4 ] [ r1; r2 ] targets
;;

let test_left_bias_union () =
  let open Routes in
  let r1 = one_of [ ((s "foo" / int /? nil) @--> fun i -> i) ] in
  let r2 = one_of [ ((s "foo" / int /? nil) @--> fun i -> -i) ] in
  Alcotest.(check (option int))
    "A union matches the left routes in preference to the right"
    (Some 10)
    (match' (union r1 r2) ~target:"foo/10")
;;

let test_map () =
  let open Routes in
  let map_option f = function
    | None -> None
    | Some x -> Some (f x)
  in
  let map_law t f r target =
    Alcotest.(
      check
        (option t)
        "Mapping a function over a route applies that function to the handler"
        (map_option f (match' (one_of [ r ]) ~target))
        (match' (one_of [ map f r ]) ~target))
  in
  let r = (s "foo" / int /? nil) @--> fun i -> i in
  map_law Alcotest.string string_of_int r "foo/5"
;;

let test_extractors () =
  let open Routes in
  let router =
    one_of
      [ ((s "foo" / str /? nil) @--> fun a -> a)
      ; ((s "numbers" / int / int64 / int32 /? nil)
        @--> fun a b c -> Printf.sprintf "%d-%Ld-%ld" a b c)
      ; ((s "bar" /? wildcard) @--> fun a -> Routes.Parts.wildcard_match a)
      ; ((s "baz" / int / s "and" //? wildcard)
        @--> fun a b -> Printf.sprintf "%d-%s" a (Routes.Parts.wildcard_match b))
      ]
  in
  Alcotest.(check (option string))
    "Can extract a string and an integer"
    (Some "Movie")
    (match' ~target:"foo/Movie" router);
  Alcotest.(check (option string))
    "Can extract multiple path parameters"
    (Some "1-2-3")
    (match' ~target:"/numbers/1/2/3" router);
  Alcotest.(check (option string))
    "Can extract empty wildcard"
    (Some "")
    (match' ~target:"/bar" router);
  Alcotest.(check (option string))
    "Can extract non-empty wildcard"
    (Some "/a")
    (match' ~target:"/bar/a" router);
  Alcotest.(check (option string))
    "Can extract non-empty wildcard ending with a slash"
    (Some "/a/")
    (match' ~target:"/bar/a/" router);
  Alcotest.(check (option string))
    "Can extract non-empty wildcard with slash in the middle"
    (Some "/a/b")
    (match' ~target:"/bar/a/b" router);
  Alcotest.(check (option string))
    "Can extract both int and wildcard"
    (Some "42-/x/y/z/")
    (match' ~target:"/baz/42/and/x/y/z/" router)
;;

let test_leading_slash_is_discarded () =
  let open Routes in
  let routes = one_of [ (s "foo" /? nil) @--> "foo"; empty @--> "empty" ] in
  Alcotest.(check (option string))
    "foo with no leading slash"
    (Some "foo")
    (match' routes ~target:"foo");
  Alcotest.(check (option string))
    "foo with leading slash"
    (Some "foo")
    (match' routes ~target:"/foo");
  Alcotest.(check (option string))
    "root with leading slash"
    (Some "empty")
    (match' routes ~target:"/");
  Alcotest.(check (option string))
    "root with no leading slash"
    (Some "empty")
    (match' routes ~target:"")
;;

let test_verify_first_parsed_route_matches () =
  let open Routes in
  let routes =
    one_of
      [ empty @--> "empty"
      ; (s "foo" / int /? nil) @--> string_of_int
      ; (s "foo" / str /? nil) @--> String.uppercase_ascii
      ; (s "foo" / bool /? nil) @--> string_of_bool
      ]
  in
  let routes' =
    one_of
      [ empty @--> "empty"
      ; ((s "foo" / str /? nil) @--> fun s -> string_of_int (String.length s))
      ; (s "foo" / int /? nil) @--> string_of_int
      ; (s "foo" / bool /? nil) @--> string_of_bool
      ]
  in
  Alcotest.(check (option string))
    "Matches the first route that parses successfully"
    (Some "121")
    (match' routes ~target:"/foo/121");
  Alcotest.(check (option string))
    "Matches the string route since int match failed"
    (Some "OCAML")
    (match' routes ~target:"/foo/ocaml");
  Alcotest.(check (option string))
    "Matches the first string route and does not go to the int matcher"
    (Some "3")
    (match' routes' ~target:"/foo/451")
;;

let test_match_routes_with_common_prefix () =
  let open Routes in
  let routes =
    one_of
      [ empty @--> "root"
      ; (s "foo" / s "bar" /? nil) @--> "one"
      ; (s "foo" / s "bar" //? nil) @--> "trail"
      ; (s "foo" /? nil) @--> "two"
      ]
  in
  Alcotest.(check (option string))
    "Matches empty route"
    (Some "root")
    (match' routes ~target:"/");
  Alcotest.(check (option string))
    "Matches first overlapping path param"
    (Some "two")
    (match' routes ~target:"/foo");
  Alcotest.(check (option string))
    "Matches first overlapping path param"
    (Some "trail")
    (match' routes ~target:"/foo/bar/");
  Alcotest.(check (option string))
    "Matches second overlapping path param"
    (Some "one")
    (match' routes ~target:"/foo/bar")
;;

let test_route_pattern () =
  let open Routes in
  let r1 = s "foo" / s "bar" /? nil in
  let r2 = s "foo" / int / bool /? nil in
  let r3 = s "foo" / str / bool //? nil in
  let r4 = s "baz" /? wildcard in
  let r5 = (s "hello" / s "world" /? nil) @--> "Route" in
  Alcotest.(check string)
    "Pretty print empty route"
    "/"
    (Format.asprintf "%a" pp_target empty);
  Alcotest.(check string) "Sprintf empty route" "/" (sprintf empty);
  Alcotest.(check string)
    "Pretty print route"
    "/foo/bar"
    (Format.asprintf "%a" pp_target r1);
  Alcotest.(check string)
    "Pretty print route with pattern"
    "/foo/:int/:bool"
    (Format.asprintf "%a" pp_target r2);
  Alcotest.(check string)
    "Sprintf route without trailing slash"
    "/foo/12/true"
    (sprintf r2 12 true);
  Alcotest.(check string)
    "Pretty print route with pattern"
    "/foo/:string/:bool/"
    (Format.asprintf "%a" pp_target r3);
  Alcotest.(check string)
    "Sprintf route with trailing slash"
    "/foo/hello/false/"
    (sprintf r3 "hello" false);
  Alcotest.(check string)
    "Pretty print route"
    "/baz/:wildcard"
    (Format.asprintf "%a" pp_target r4);
  Alcotest.(check string)
    "Pretty print route"
    "/hello/world"
    (Format.asprintf "%a" pp_route r5)
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

let test_custom_pattern () =
  let open Routes in
  let shape = pattern shape_to_string shape_of_string ":shape" in
  let shape' = custom ~serialize:shape_to_string ~parse:shape_of_string ~label:":shape" in
  let r1 () =
    (s "foo" / int / s "shape" / shape' /? nil)
    @--> fun c shape -> Printf.sprintf "%d - %s" c (shape_to_string shape)
  in
  let r2 () = s "shape" / shape / s "create" /? nil in
  let router = one_of [ r1 () ] in
  Alcotest.(check (option string))
    "Can match a custom pattern"
    (Some "12 - circle")
    (match' router ~target:"/foo/12/shape/Circle");
  Alcotest.(check (option string))
    "Invalid shape does not match"
    None
    (match' router ~target:"/foo/12/shape/rectangle");
  Alcotest.(check string)
    "Can pretty print custom pattern"
    "/foo/:int/shape/:shape"
    (Format.asprintf "%a" pp_route (r1 ()));
  Alcotest.(check string)
    "Can serialize route with custom params"
    "/shape/square/create"
    (sprintf (r2 ()) Square)
;;

let test_matcher_discards_query_params () =
  let open Routes in
  let routes = one_of [ ((s "foo" / str /? nil) @--> fun x -> x); empty @--> "root" ] in
  Alcotest.(check (option string))
    "Discards query params"
    (Some "hello")
    (match' routes ~target:"/foo/hello?baz=bar");
  Alcotest.(check (option string))
    "Discards query params"
    (Some "root")
    (match' routes ~target:"?baz=bar")
;;

let test_prefixing_targets () =
  let open Routes in
  let add_route path1 path2 handler (routes1, routes2) =
    let routes1 =
      routes1
      |> add_route ((path1 / path2 /? nil) @--> handler)
      |> add_route ((path1 / path2 //? nil) @--> handler)
    in
    let routes2 =
      routes2
      |> add_route ((path1 /~ (path2 /? nil)) @--> handler)
      |> add_route ((path1 /~ (path2 //? nil)) @--> handler)
    in
    routes1, routes2
  in
  let check_target nb t (routes1, routes2) target =
    Alcotest.(check (option t))
      (Printf.sprintf "prefix test %d" nb)
      (match' routes1 ~target)
      (match' routes2 ~target)
  in
  let routes =
    (one_of [], one_of [])
    |> add_route (s "foo") (s "bar") 10
    |> add_route (s "foo") int (fun n -> n)
  in
  check_target 1 Alcotest.int routes "foo/bar";
  check_target 2 Alcotest.int routes "foo/bar/10";
  check_target 3 Alcotest.int routes "foo/10"
;;

let () =
  let tests =
    [ "Empty router has no match", `Quick, test_no_match
    ; "Can extract path parameters", `Quick, test_extractors
    ; "Leading slash is discarded", `Quick, test_leading_slash_is_discarded
    ; ( "Responds with the first successful match"
      , `Quick
      , test_verify_first_parsed_route_matches )
    ; "Matches routes with common prefix", `Quick, test_match_routes_with_common_prefix
    ; "Pretty print route", `Quick, test_route_pattern
    ; "Can work with custom patterns", `Quick, test_custom_pattern
    ; "Discards query params", `Quick, test_matcher_discards_query_params
    ; "Can add a route", `Quick, test_add_route
    ; "Union of routers is lawful", `Quick, test_union_routes
    ; "Unions are left-biased", `Quick, test_left_bias_union
    ; "Maps are lawful", `Quick, test_map
    ; "Paths can be prefixed to targets", `Quick, test_prefixing_targets
    ]
  in
  Alcotest.run "Tests" [ "Routes tests", tests ]
;;
