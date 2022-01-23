type spec =
  { keys : string list
  ; route : string
  ; pattern : Trie.Key.t list
  ; captures : [ `Param | `Wildcard ] list
  }

type 'a route =
  { spec : spec
  ; payload : 'a
  }

type 'a t = 'a route Trie.t

let make_spec p =
  let parts = Util.split_path p in
  let keys, pattern =
    let rec aux parts keys pattern =
      match parts with
      | [] -> List.rev keys, List.rev pattern
      | "" :: _ -> invalid_arg "Invalid route pattern"
      | x :: xs ->
        if String.get x 0 = ':'
        then (
          if String.length x = 1 then invalid_arg "Route parameter must have a name";
          let name = String.sub x 1 (String.length x - 1) in
          aux xs (name :: keys) (Trie.Key.Capture :: pattern))
        else if x = "*"
        then (
          match xs with
          | [] -> aux [] keys (Trie.Key.Wildcard :: pattern)
          | _ -> invalid_arg "Wildcard pattern must be at the end of a route")
        else aux xs keys (Trie.Key.Match x :: pattern)
    in
    aux parts [] []
  in
  let captures =
    List.filter_map
      (function
        | Trie.Key.Match _ -> None
        | Trie.Key.Wildcard -> Some `Wildcard
        | Capture -> Some `Param)
      pattern
  in
  { keys; route = p; pattern; captures }
;;

let route pattern payload =
  let spec = make_spec pattern in
  { spec; payload }
;;

let one_of routes =
  let routes = List.rev routes in
  List.fold_left
    (fun routes route ->
      Trie.add ~raise_on_ambiguous:true route.spec.pattern route routes)
    Trie.empty
    routes
;;

type 'a parse_result =
  { params : (string * string) list
  ; wildcard : string option
  ; data : 'a
  }

let extract_params spec captures =
  let rec aux params captures acc =
    match params, captures with
    | [], _ -> List.rev acc, captures, params
    | `Param :: _, [] ->
      failwith
        "Invalid state. Number of parameters will always equal the number of captures"
    | `Param :: params, x :: xs -> aux params xs (x :: acc)
    | [ `Wildcard ], _ -> List.rev acc, captures, params
    | `Wildcard :: _, _ ->
      failwith "Invalid state. Wildcards can only occur at the end of the route"
  in
  aux spec.captures captures []
;;

let to_result payload spec captures =
  let vars, captures, params = extract_params spec captures in
  let wildcard =
    match params, captures with
    | [ `Wildcard ], [] -> None
    | [ `Wildcard ], parts -> Some (String.concat "/" parts)
    | _, _ -> None
  in
  { data = payload; wildcard; params = List.combine spec.keys vars }
;;

let match' router ~target =
  let target = Util.split_path target in
  let routes, captures = Trie.feed_params router target in
  match routes with
  | [] -> None
  | [ { spec; payload } ] -> Some (to_result payload spec captures)
  | _ :: _ ->
    failwith
      "This branch should never be reached. We create the router with a configuration \
       option that disables ambiguous routes in the trie."
;;
