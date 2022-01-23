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
  let rec aux t params =
    match t, params with
    | { parsers = []; _ }, [] -> []
    | { parsers = rs; _ }, [] -> rs
    | { parsers = rs; _ }, [ "" ] -> rs
    | { parsers = rs; wildcard; _ }, _ when wildcard -> rs
    | { children; capture; _ }, x :: xs ->
      (match KeyMap.find_opt x children with
      | None ->
        (match capture with
        | None -> []
        | Some t' -> aux t' xs)
      | Some m' -> aux m' xs)
  in
  aux t params
;;

let add k v t =
  let rec aux k t =
    match k, t with
    | [], ({ parsers = x; _ } as n) -> { n with parsers = v :: x }
    | x :: r, ({ children; capture; _ } as n) ->
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
      | Key.Wildcard -> { n with parsers = v :: n.parsers; wildcard = true })
  in
  aux k t
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
