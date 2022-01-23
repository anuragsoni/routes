module Key : sig
  type t =
    | Match : string -> t
    | Capture : t
    | Wildcard : t
end

type 'a t

exception Ambiguous_routes of string

val empty : 'a t
val feed_params : 'a t -> string list -> 'a list * string list
val add : raise_on_ambiguous:bool -> Key.t list -> 'a -> 'a t -> 'a t
val union : 'a t -> 'a t -> 'a t
