type 'a t

val return : 'a -> 'a t
val fail : 'a t
val empty : unit t
val take_token : string t
val run : 'a t -> string list -> ('a * string list) option
val append : 'a t -> 'a t -> 'a t
val choose : 'a t list -> 'a t
val fmap : 'a t -> f:('a -> 'b) -> 'b t
val bind : 'a t -> f:('a -> 'b t) -> 'b t
val apply : ('a -> 'b) t -> 'a t -> 'b t
val int : int t
val int32 : int32 t
val int64 : int64 t
val bool : bool t
val str : string t
val string : string -> string t
val s : string -> unit t

module Infix : sig
  val ( >>= ) : 'a t -> ('a -> 'b t) -> 'b t
  val ( >>| ) : 'a t -> ('a -> 'b) -> 'b t
  val ( <$> ) : ('a -> 'b) -> 'a t -> 'b t
  val ( <*> ) : ('a -> 'b) t -> 'a t -> 'b t
  val ( *> ) : 'b t -> 'a t -> 'a t
  val ( <* ) : 'a t -> 'b t -> 'a t
  val ( <+> ) : 'a t -> 'a t -> 'a t
  val ( <|> ) : 'a t -> 'a t -> 'a t
end
