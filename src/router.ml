module Key = struct
  type t =
    | PMatch : string -> t
    | PCapture : t

  let compare a b =
    match a, b with
    | PMatch w1, PMatch w2 -> String.compare w1 w2
    | PMatch _, PCapture -> -1
    | PCapture, PCapture -> 0
    | PCapture, PMatch _ -> 1
  ;;

  let is_match = function
    | PMatch _ -> true
    | _ -> false
  ;;
end

module KeyMap = Map.Make (Key)

type key = Key.t list

type 'a node =
  { parsers : 'a list
  ; children : 'a node KeyMap.t
  ; can_capture : bool
  ; max_path_len : int
  }

type 'a t = 'a node

let empty =
  { parsers = []; children = KeyMap.empty; can_capture = false; max_path_len = 0 }
;;

let is_empty = function
  | { parsers = []; children = m; _ } -> KeyMap.is_empty m
  | _ -> false
;;

let feed_params t params =
  let rec aux t params captures =
    match t, params with
    | { max_path_len; _ }, _ when List.length params > max_path_len -> [], []
    | { parsers = []; _ }, [] -> [], []
    | { parsers = rs; _ }, [] -> List.rev rs, List.rev captures
    | { children = m; can_capture; _ }, x :: xs ->
      (match KeyMap.find_opt (Key.PMatch x) m with
      | None ->
        if can_capture
        then (
          match KeyMap.find_opt Key.PCapture m with
          | None -> [], []
          | Some m' -> aux m' xs (x :: captures))
        else [], []
      | Some m' -> aux m' xs captures)
  in
  aux t params []
;;

let add k v t =
  let rec aux k t =
    match k, t with
    | [], ({ parsers = x; _ } as n) -> { n with parsers = v :: x }
    | x :: r, ({ children = m; max_path_len; _ } as n) ->
      let is_match = Key.is_match x in
      let path_len = List.length k in
      let max_path_len = if path_len > max_path_len then path_len else max_path_len in
      let t' =
        match KeyMap.find_opt x m with
        | None -> empty
        | Some v -> v
      in
      let t'' = aux r t' in
      { n with children = KeyMap.add x t'' m; can_capture = not is_match; max_path_len }
  in
  aux k t
;;
