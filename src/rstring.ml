open Astring

type t = String.Sub.t

let of_string x = String.sub x
let to_string x = String.Sub.to_string x
let drop_while ~f t = String.Sub.drop ~sat:f t

let drop_prefix prefix t =
  if String.Sub.is_prefix ~affix:(String.sub prefix) t
  then Some (String.Sub.drop ~max:(String.length prefix) t)
  else None
;;

let take_while ~f t =
  String.Sub.span ~sat:f t

let take_while_opt ~f t =
  let take, rest = take_while ~f t in
  Some (String.Sub.to_string take, rest)

let is_empty t =
  String.Sub.is_empty t

let to_int = String.to_int

let to_int32 = String.to_int32

let to_int64 = String.to_int64

let to_bool = String.to_bool

let tail t = String.Sub.tail t

let get t i = String.Sub.get t i
