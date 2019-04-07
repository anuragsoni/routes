type 'a t

val drop_while
  :  f:(char -> bool)
  -> Astring.String.sub
  -> (unit * Astring.String.sub) option

val take_while
  :  f:(char -> bool)
  -> Astring.String.sub
  -> (string * Astring.String.sub) option

val drop_prefix : string -> Astring.String.sub -> (unit * Astring.String.sub) option
val map : ('a -> ('b * 'c) option) -> f:('b -> 'd) -> 'a -> ('d * 'c) option

val filter_map
  :  ('a -> ('b * 'c) option)
  -> f:('b -> 'd option)
  -> 'a
  -> ('d * 'c) option

val run : ('a -> 'b) -> 'a -> 'b
val take_token : Astring.String.sub -> (string * Astring.String.sub) option
