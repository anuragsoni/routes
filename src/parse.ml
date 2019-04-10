type 'a t = Rstring.t -> ('a * Rstring.t) option

let drop_while ~f t = Some ((), Rstring.drop_while ~f t)
let take_while ~f t = Rstring.take_while_opt ~f t

let drop_prefix prefix t =
  match Rstring.drop_prefix prefix t with
  | None -> None
  | Some r -> Some ((), r)
;;

let map t ~f p =
  match t p with
  | None -> None
  | Some (x, p') -> Some (f x, p')
;;

let filter_map t ~f p =
  match t p with
  | None -> None
  | Some (x, p') ->
    (match f x with
    | None -> None
    | Some y -> Some (y, p'))
;;

let run t s = t s
let take_token = take_while ~f:(fun x -> x <> '/')
