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

let test_method_match () =
  let open Routes in
  let routes =
    one_of
      [ Some `GET, nil @--> "No match"
      ; Some (`Other "PATCH"), (s "hello" / s "world" /? nil) @--> "Hello World"
      ]
  in
  Alcotest.(check (option string))
    "Matches handler with patch method"
    (Some "Hello World")
    (match' ~meth:(`Other "PATCH") ~target:"hello/world" routes);
  Alcotest.(check (option string))
    "Correct target but wrong method results in no match"
    None
    (match' ~meth:`GET ~target:"hello/world" routes)

let test_extractors () =
  let open Routes in
  let router =
    one_of
      [ (Some `GET, (s "foo" / str /? nil) @--> fun a -> a)
      ; ( None
        , (s "numbers" / int / int64 / int32 /? nil)
          @--> fun a b c -> Printf.sprintf "%d-%Ld-%ld" a b c )
      ]
  in
  Alcotest.(check (option string))
    "Can extract a string and an integer"
    (Some "Movie")
    (match' ~meth:`GET ~target:"foo/Movie" router);
  Alcotest.(check (option string))
    "Can extract multiple path parameters"
    (Some "1-2-3")
    (match' ~target:"/numbers/1/2/3" router)

let () =
  let tests =
    [ "Empty router has no match", `Quick, test_no_match
    ; "Match on method", `Quick, test_method_match
    ; "Can extract path parameters", `Quick, test_extractors
    ]
  in
  Alcotest.run "Tests" [ "Routes tests", tests ]
