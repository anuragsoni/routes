type 'a t

val drop_while : f:(char -> bool) -> Rstring.t -> (unit * Rstring.t) option
val take_while : f:(char -> bool) -> Rstring.t -> (string * Rstring.t) option
val drop_prefix : string -> Rstring.t -> (unit * Rstring.t) option
val map : ('a -> ('b * 'c) option) -> f:('b -> 'd) -> 'a -> ('d * 'c) option

val filter_map
  :  ('a -> ('b * 'c) option)
  -> f:('b -> 'd option)
  -> 'a
  -> ('d * 'c) option

val run : ('a -> 'b) -> 'a -> 'b
val take_token : Rstring.t -> (string * Rstring.t) option
