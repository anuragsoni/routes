open Astring

type t

val split_paths : string -> string list * string
val init : string -> t
val parse_param : t -> (String.t * t) option
val is_finished : t -> bool
val bind : f:(String.t -> 'a option) -> t -> ('a * t) option
