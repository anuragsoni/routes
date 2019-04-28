(** Typed routing for OCaml.
    [Routes] provides combinators for adding typed routing
    to OCaml applications. The core library will be independent
    of any particular web framework or runtime.
*)

module Method : sig
  (** HTTP methods. This is an optional input for route matching.
      The current types are chosen to be compatible with what Httpaf uses - {{:https://github.com/inhabitedtype/httpaf/blob/c2ee924eaccd2adb2e6aea0b9bc6a0ffe6132723/lib/method.ml} link}. *)
  type t =
    [ `CONNECT
    | `DELETE
    | `GET
    | `HEAD
    | `OPTIONS
    | `Other of string
    | `POST
    | `PUT
    | `TRACE
    ]
end

(** ['a t] represents a path parameter of type 'a. *)
type 'a t

type 'a route
type 'a route'
type 'a router

val return : 'a -> 'a t
(** [return v] is a path param parser that always returns v. *)

val apply : ('a -> 'b) t -> 'a t -> 'b t
(** [apply f t]  applies a function f that is wrapped inside
    a ['a t] context to a path param parser.
    f <*> p is the same as f >>= fun f -> map ~f p *)

val fmap : f:('a -> 'b) -> 'a t -> 'b t
(** [fmap ~f p] parses a path param and forwards the result
    to the function f if the parsing succeeds. *)

val s : string -> unit t
(** [s word] returns a path parser that matches [word] exactly
    and discards the result. *)

val int : int t
(** [int] parses a path parmeter and succeeds if its an integer. *)

val str : string t
(** [str] parses a path param and returns it as a string. *)

val empty : unit t
(** [empty] matches an empty target. This can be used to match against "/". *)

val choose : (Method.t list * 'a t) list -> 'a router
(** [choose] accepts a list of path param parsers and converts them to a router. *)

val run : ('a -> 'b) router -> target:string -> meth:Method.t -> req:'a -> 'b option
(** [run] is used to run the router. It accepts a target url string, HTTP method verb
    a request of any type (which is forwarded as the last parameter to the handler functions).
    If a route matches it runs the attached handler and returns the result.
*)

module Infix : sig
  val ( <*> ) : ('a -> 'b) t -> 'a t -> 'b t
  val ( </> ) : ('a -> 'b) t -> 'a t -> 'b t
  val ( >>| ) : 'a t -> ('a -> 'b) -> 'b t
  val ( <$> ) : ('a -> 'b) -> 'a t -> 'b t
  val ( *> ) : 'a t -> 'b t -> 'b t
  val ( <* ) : 'a t -> 'b t -> 'a t
  val ( <$ ) : 'a -> 'b t -> 'a t
end
