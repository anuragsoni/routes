open Astring

module StringUtils = struct
  let drop_while ~f t = String.Sub.drop ~sat:f t

  let drop_prefix prefix t =
    let len = String.length prefix in
    if String.Sub.is_prefix ~affix:(String.sub prefix) t
    then Some (String.Sub.drop ~max:len t)
    else None
  ;;

  let take_while ~f t =
    let take, rest = String.Sub.span ~sat:f t in
    Some (String.Sub.to_string take, rest)
  ;;
end

type 'a t = String.Sub.t -> ('a * String.Sub.t) option

let drop_while ~f t = Some ((), StringUtils.drop_while ~f t)
let take_while ~f t = StringUtils.take_while ~f t

let drop_prefix prefix t =
  match StringUtils.drop_prefix prefix t with
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
