type t
val of_string : string -> t
val to_string : t -> string
val drop_while : f:(char -> bool) -> t -> t
val drop_prefix : string -> t -> t option
val take_while :
  f:(char -> bool) ->
  t -> t * t
val take_while_opt :
  f:(char -> bool) ->
  t -> (string * t) option
val is_empty : t -> bool
val to_int : string -> int option
val to_int32 : string -> int32 option
val to_int64 : string -> int64 option
val to_bool : string -> bool option
val tail : t -> t
val get : t -> int -> char
