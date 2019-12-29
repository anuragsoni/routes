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
  }

type 'a t = 'a node

let empty = { parsers = []; children = KeyMap.empty; capture = None }

let is_empty = function
  | { parsers = []; children; _ } -> KeyMap.is_empty children
  | _ -> false
;;

exception Not_equal

let str_equal target start stop s =
  if String.length s <> stop - start
  then false
  else (
    try
      for i = start to stop - 1 do
        if target.[i] <> s.[i - start] then raise_notrace Not_equal
      done;
      true
    with
    | Not_equal -> false)
;;

let feed_params t params =
  let len = String.length params in
  let rec aux idx captures t =
    if idx >= len
    then t.parsers, List.rev captures, ""
    else (
      let c =
        match String.index_from_opt params idx '/' with
        | None -> len
        | Some i -> i
      in
      match KeyMap.find_first_opt (fun k -> str_equal params idx c k) t.children with
      | None ->
        (match t.capture with
        | None -> [], [], params
        | Some t' -> aux (c + 1) (String.sub params idx (c - idx) :: captures) t')
      | Some (_, m') -> aux (c + 1) captures m')
  in
  aux 0 [] t
;;

let add k v t =
  let rec aux k t =
    match k, t with
    | [], ({ parsers = x; _ } as n) -> { n with parsers = v :: x }
    | x :: r, ({ children; capture; _ } as n) ->
      (match x with
      | Key.PMatch w ->
        let t' =
          match KeyMap.find_opt w children with
          | None -> empty
          | Some v -> v
        in
        let t'' = aux r t' in
        { n with children = KeyMap.add w t'' children }
      | Key.PCapture ->
        let t' =
          match capture with
          | None -> empty
          | Some v -> v
        in
        let t'' = aux r t' in
        { n with capture = Some t'' })
  in
  aux k t
;;
