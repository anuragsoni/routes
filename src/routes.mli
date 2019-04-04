(** Typed routing for OCaml.

    [Routes] provides combinators for adding typed routing
    to OCaml applications. The core library will be independent
    of any particular web framework or runtime. It uses
    continuations in an approach outlined by the following
    talk by Daniel Patterson:
    {{: https://dbp.io/talks/2016/fn-continuations-haskell-meetup.pdf} Typed routing with continuations}
*)

(** [state] is the state that is threaded through the router during parsing. *)
module RouterState : sig
  type ('req, 'meth) state

  val get_request : ('req, 'meth) state -> 'req
end

open RouterState

type ('req, 'res, 'meth) route = ('req, 'meth) state -> 'res option

(** [s str] does an exact match on the input string.
    It consumes and discards the string and as a result the handler doesn't
    need to work on the parsed string. If there are no paths left to
    match on given URL, or the match failes, the whole
    route matching fails. *)
val s : string -> ('req, 'meth) state -> (('req, 'meth) state * ('a -> 'a)) option

(** [empty] confirms that there is nothing left to consume in the URL's paths. *)
val empty : ('req, 'meth) state -> (('req, 'meth) state * ('a -> 'a)) option

(** [anything] will consume and drop any pathvalue, irrespective of its type. *)
val anything : ('req, 'meth) state -> (('req, 'meth) state * ('a -> 'a)) option

(** [method'] meth will match on the provided HTTP method of a request. *)
val method' : 'meth -> ('req, 'meth) state -> (('req, 'meth) state * ('a -> 'a)) option

(** [str] will match and extract a string value that will be forwarded to
    the request handler. *)
val str : ('req, 'meth) state -> (('req, 'meth) state * ((string -> 'a) -> 'a)) option

(** [int] will match and extract an integer value that will be forwarded to
    the request handler. *)
val int : ('req, 'meth) state -> (('req, 'meth) state * ((int -> 'a) -> 'a)) option

(** [int32] will match and extract a 32 bit integer. *)
val int32 : ('req, 'meth) state -> (('req, 'meth) state * ((int32 -> 'a) -> 'a)) option

(** [int64] will match and extract a 64 bit integer. *)
val int64 : ('req, 'meth) state -> (('req, 'meth) state * ((int64 -> 'a) -> 'a)) option

(** [boolean] will match and extract a boolean value. *)
val boolean : ('req, 'meth) state -> (('req, 'meth) state * ((bool -> 'a) -> 'a)) option

(** [</>] is used to connect two path parsers. Ex: str </> int
    will first try and parse a string, followed by an integer.
    If any of the parsers fail, the whole route matching fails.*)
val ( </> )
  :  ('req -> ('req * ('a -> 'b)) option)
  -> ('req -> ('req * ('b -> 'c)) option)
  -> 'req
  -> ('req * ('a -> 'c)) option

(** [==>] connects a route matcher to a user provided handler. The provided
    handler will receive the entire request object, and any other types that
    were extracted while parsing the route. *)
val ( ==> )
  :  (('req, 'meth) state -> (('req, 'meth) state * ('k -> 'res)) option)
  -> (('req, 'meth) state -> 'k)
  -> ('req, 'meth) state
  -> 'res option

(** [match'] takes a request, target, method and runs it through a
    list of route matching patterns. It will stop at the first match. *)
val match'
  :  req:'req
  -> target:string
  -> meth:'meth
  -> ('req, 'res, 'meth) route list
  -> 'res option

(** [match_with_state] takes a router state and runs it through a list of
    routes. This is useful when using handlers that in-turn define
    their own routes. *)
val match_with_state
  :  state:('req, 'meth) state
  -> ('req, 'res, 'meth) route list
  -> 'res option
