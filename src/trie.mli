module Key : sig
  type t =
    | Match : string -> t
    | Capture : t
    | Wildcard : t
end

type 'a t

val empty : 'a t
val feed_params : 'a t -> string list -> 'a list
val add : Key.t list -> 'a -> 'a t -> 'a t
val union : 'a t -> 'a t -> 'a t
