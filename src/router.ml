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
end

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
        match KeyMap.find_opt x m with
        | None -> empty
        | Some v -> v
      in
      let t'' = ins (r, t') in
      Node (v, KeyMap.add x t'' m)
  in
  ins (l, t)
;;
