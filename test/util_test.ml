let test_path_split () =
  let open Routes.Routes_private.Util in
  Alcotest.(check (list string)) "Empty string" [] (split_path "");
  Alcotest.(check (list string)) "Root path" [] (split_path "/");
  Alcotest.(check (list string)) "Leading slash" [ "a"; "b"; "c" ] (split_path "/a/b/c");
  Alcotest.(check (list string))
    "No leading slash"
    [ "a"; "b"; "c" ]
    (split_path "a/b/c");
  Alcotest.(check (list string))
    "Discard query param"
    [ "foo" ]
    (split_path "foo?foo=bar");
  Alcotest.(check (list string)) "Discard query param" [] (split_path "?foo=bar");
  Alcotest.(check (list string))
    "Discard query param"
    [ "foo"; "bar" ]
    (split_path "foo/bar?a=1")
;;

let suite = [ "Test path split", `Quick, test_path_split ]
