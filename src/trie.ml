module Key = struct
  type t =
    | Match : string -> t
    | Capture : t
    | Wildcard : t
end

module KeyMap = Map.Make (String)

type 'a node =
  { parsers : 'a list
  ; children : 'a node KeyMap.t
  ; capture : 'a node option
  ; wildcard : bool
  }

type 'a t = 'a node

let empty = { parsers = []; children = KeyMap.empty; capture = None; wildcard = false }

let feed_params t params =
  let rec aux t params captures =
    match t, params with
    | { parsers = []; _ }, [] -> [], List.rev captures
    | { parsers = rs; _ }, [] -> rs, List.rev captures
    | { parsers = rs; _ }, [ "" ] -> rs, List.rev ("" :: captures)
    | { parsers = rs; wildcard; _ }, _ when wildcard -> rs, List.rev captures @ params
    | { children; capture; _ }, x :: xs ->
      (match KeyMap.find_opt x children with
      | None ->
        (match capture with
        | None -> [], List.rev captures
        | Some t' -> aux t' xs (x :: captures))
      | Some m' -> aux m' xs captures)
  in
  aux t params []
;;

exception Ambiguous_routes of string

let serialize_pattern ks =
  ks
  |> ListLabels.map ~f:(function
         | Key.Match s -> s
         | Key.Wildcard -> "*wildcard"
         | Key.Capture -> ":capture")
  |> String.concat "/"
;;

let add ~raise_on_ambiguous keys v t =
  let rec aux k t =
    match k, t with
    | [], ({ parsers = []; _ } as n) -> { n with parsers = [ v ] }
    | [], ({ parsers = x; _ } as n) ->
      if raise_on_ambiguous then raise (Ambiguous_routes (serialize_pattern keys));
      { n with parsers = v :: x }
    | x :: r, ({ children; capture; _ } as n) ->
      if raise_on_ambiguous && n.wildcard
      then raise (Ambiguous_routes (serialize_pattern keys));
      (match x with
      | Key.Match w ->
        let t' =
          match KeyMap.find_opt w children with
          | None -> empty
          | Some v -> v
        in
        let t'' = aux r t' in
        { n with children = KeyMap.add w t'' children }
      | Key.Capture ->
        let t' =
          match capture with
          | None -> empty
          | Some v -> v
        in
        let t'' = aux r t' in
        { n with capture = Some t'' }
      | Key.Wildcard ->
        if raise_on_ambiguous
        then
          if (not (KeyMap.is_empty n.children)) || Option.is_some n.capture
          then raise (Ambiguous_routes (serialize_pattern keys));
        { n with parsers = v :: n.parsers; wildcard = true })
  in
  aux keys t
;;

let rec union t1 t2 =
  let parsers = t1.parsers @ t2.parsers in
  let children =
    KeyMap.merge
      (fun _ l r ->
        match l, r with
        | None, None -> assert false
        | None, Some r -> Some r
        | Some l, None -> Some l
        | Some l, Some r -> Some (union l r))
      t1.children
      t2.children
  in
  let capture =
    match t1.capture, t2.capture with
    | None, None -> None
    | Some l, None -> Some l
    | None, Some r -> Some r
    | Some l, Some r -> Some (union l r)
  in
  let wildcard =
    match t1.wildcard, t2.wildcard with
    | false, false -> false
    | true, true -> true
    | false, true | true, false ->
      failwith "Attemp to union wildcard and non-wildcard pattern"
  in
  { parsers; children; capture; wildcard }
;;
