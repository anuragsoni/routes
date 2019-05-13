module Key = struct
  type t =
    | PMatch : string -> t
    | PCapture : t
end

module KeyMap = Map.Make (String)

type key = Key.t list

type 'a node =
  { parsers : 'a list
  ; children : 'a node KeyMap.t
  ; capture : 'a node option
  ; max_path_len : int
  }

type 'a t = 'a node

let empty = { parsers = []; children = KeyMap.empty; capture = None; max_path_len = 0 }

let is_empty = function
  | { parsers = []; children; _ } -> KeyMap.is_empty children
  | _ -> false
;;

let feed_params t params =
  let rec aux t params captures =
    match t, params with
    | { max_path_len; _ }, _ when List.length params > max_path_len -> [], []
    | { parsers = []; _ }, [] -> [], []
    | { parsers = rs; _ }, [] -> List.rev rs, List.rev captures
    | { children; capture; _ }, x :: xs ->
      (match KeyMap.find_opt x children with
      | None ->
        (match capture with
        | None -> [], []
        | Some t' -> aux t' xs (x :: captures))
      | Some m' -> aux m' xs captures)
  in
  aux t params []
;;

let add k v t =
  let rec aux k t =
    match k, t with
    | [], ({ parsers = x; _ } as n) -> { n with parsers = v :: x }
    | x :: r, ({ children; max_path_len; capture; _ } as n) ->
      let path_len = List.length k in
      let max_path_len = if path_len > max_path_len then path_len else max_path_len in
      (match x with
      | Key.PMatch w ->
        let t' =
          match KeyMap.find_opt w children with
          | None -> empty
          | Some v -> v
        in
        let t'' = aux r t' in
        { n with children = KeyMap.add w t'' children; max_path_len }
      | Key.PCapture ->
        let t' =
          match capture with
          | None -> empty
          | Some v -> v
        in
        let t'' = aux r t' in
        { n with capture = Some t''; max_path_len })
  in
  aux k t
;;
