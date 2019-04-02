type ('req, 'meth) state

val init : 'req -> string -> 'meth -> ('req, 'meth) state

type ('req, 'res, 'meth) route = ('req, 'meth) state -> 'res option

val path : string -> ('req, 'meth) state -> (('req, 'meth) state * ('a -> 'a)) option
val non_empty : ('req, 'meth) state -> (('req, 'meth) state * ('a -> 'a)) option
val anything : ('req, 'meth) state -> (('req, 'meth) state * ('a -> 'a)) option
val method' : 'meth -> ('req, 'meth) state -> (('req, 'meth) state * ('a -> 'a)) option
val str : ('req, 'meth) state -> (('req, 'meth) state * ((string -> 'a) -> 'a)) option
val int : ('req, 'meth) state -> (('req, 'meth) state * ((int -> 'a) -> 'a)) option

val ( </> )
  :  ('req -> ('req * ('a -> 'b)) option)
  -> ('req -> ('req * ('b -> 'c)) option)
  -> 'req
  -> ('req * ('a -> 'c)) option

val ( ==> ) :
  (('req, 'meth) state -> (('req, 'meth) state * ('k -> 'res)) option) ->
  ('req -> 'k) -> ('req, 'meth) state -> 'res option

val route : ('req, 'res, 'meth) route list -> ('req, 'meth) state -> 'res option
