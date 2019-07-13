let test_path_split () =
  let open Routes.Routes_private.Util in
  Alcotest.(check (list string)) "Empty string" [] (split_path true "");
  Alcotest.(check (list string)) "Root path" [] (split_path true "/");
  Alcotest.(check (list string))
    "Root path keep trailing slash"
    [ "" ]
    (split_path false "/");
  Alcotest.(check (list string))
    "Leading slash"
    [ "a"; "b"; "c" ]
    (split_path true "/a/b/c");
  Alcotest.(check (list string))
    "No leading slash"
    [ "a"; "b"; "c" ]
    (split_path true "a/b/c");
  Alcotest.(check (list string))
    "Discard trailing Slash"
    [ "a"; "b"; "c" ]
    (split_path true "a/b/c/");
  Alcotest.(check (list string))
    "Keep trailing Slash"
    [ "a"; "b"; "c"; "" ]
    (split_path false "a/b/c/");
  Alcotest.(check (list string))
    "Discard query param"
    [ "foo" ]
    (split_path true "foo?foo=bar");
  Alcotest.(check (list string)) "Discard query param" [] (split_path true "?foo=bar");
  Alcotest.(check (list string))
    "Discard query param"
    [ "foo"; "bar" ]
    (split_path true "foo/bar?a=1")
;;

let suite = [ "Test path split", `Quick, test_path_split ]
