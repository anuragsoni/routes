type t

val create : prefix:string list -> matched:string list -> t
val matched : t -> string list
val prefix : t -> string
val wildcard_match : t -> string
val of_parts : string -> t
