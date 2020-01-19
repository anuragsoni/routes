type ('a, 'b) t

type ('a, 'b) req
type 'b route

val int : ('a, 'b) t -> (int -> 'a, 'b) t
val str : ('a, 'b) t -> (string -> 'a, 'b) t
val bool : ('a, 'b) t -> (bool -> 'a, 'b) t
val s : string -> ('a, 'b) t -> ('a, 'b) t
val ( </> ) : (('a, 'b) t -> 'c) -> ('d -> ('a, 'b) t) -> 'd -> 'c

val ( ==> ) : ('a, 'b) req -> 'a -> 'b route


val meth' : string -> (('a, 'a) t -> ('b, 'c) t) -> ('b, 'c) req
