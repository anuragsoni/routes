module Key = struct
  type t =
    | PMatch : string -> t
    | PCapture : t

  let equal a b =
    match a, b with
    | PCapture, PCapture -> true
    | PMatch w1, PMatch w2 when w1 = w2 -> true
    | _ -> false
  ;;

  let compare a b =
    match a, b with
    | PMatch w1, PMatch w2 -> String.compare w1 w2
    | PMatch _, PCapture -> -1
    | PCapture, PCapture -> 0
    | PCapture, PMatch _ -> 1
  ;;

  let matches_string k s =
    match k with
    | PMatch w -> w = s
    | PCapture -> true
  ;;
end

let extract_key_prefix a b =
  let rec aux left right acc =
    match left, right with
    | [], _ -> List.rev acc, [], right
    | _, [] -> List.rev acc, left, []
    | x :: xs, y :: ys ->
      if Key.equal x y then aux xs ys (x :: acc) else List.rev acc, left, right
  in
  aux a b []
;;

let consume_pattern ps xs =
  let rec aux ps xs acc =
    match ps, xs with
    | [], [] -> Some (List.rev acc)
    | [], _ -> None
    | _, [] -> None
    | p :: ps', x :: xs' ->
      (match p with
      | Key.PCapture -> aux ps' xs' (x :: acc)
      | Key.PMatch w when w = x -> aux ps' xs' acc
      | _ -> None)
  in
  aux ps xs []
;;

module KeyMap = Map.Make (Key)

type key = Key.t list
type 'a t = Node of 'a list * 'a t KeyMap.t

let empty = Node ([], KeyMap.empty)

let is_empty = function
  | Node ([], m1) -> KeyMap.is_empty m1
  | _ -> false
;;

let feed_params t params =
  let rec aux t params captures =
    match t, params with
    | Node ([], _), [] -> [], []
    | Node (rs, _), [] -> List.rev rs, List.rev captures
    | Node (_, m), x :: xs ->
      (match KeyMap.find_opt (Key.PMatch x) m with
      | None ->
        (match KeyMap.find_opt Key.PCapture m with
        | None -> [], []
        | Some m' -> aux m' xs (x :: captures))
      | Some m' -> aux m' xs captures)
  in
  aux t params []
;;

let add l v t =
  let rec ins = function
    | [], Node (x, m) -> Node (v :: x, m)
    | x :: r, Node (v, m) ->
      let t' =
        try KeyMap.find x m with
        | Not_found -> empty
      in
      let t'' = ins (r, t') in
      Node (v, KeyMap.add x t'' m)
  in
  ins (l, t)
;;
