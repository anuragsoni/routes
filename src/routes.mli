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

type 'a router

val return : 'a -> 'a t
(** [return v] is a path param parser that always returns v. *)

val apply : ('a -> 'b) t -> 'a t -> 'b t
(** [apply f t]  applies a function f that is wrapped inside
    a ['a t] context to a path param parser.
    f <*> p is the same as f >>= fun f -> map ~f p *)

val s : string -> string t
(** [s word] returns a path parser that matches [word] exactly. *)

val int : int t
(** [int] parses a path parmeter and succeeds if its an integer. *)

val int32 : int32 t
(** [int32] parses a path parameter and succeeds if its a valid 32 bit integer. *)

val int64 : int64 t
(** [int64] parses a path parameter and succeeds if its a valid 64 bit integer. *)

val bool : bool t
(** [bool] parses a path parameter and succeeds if its either "true" or "false". *)

val str : string t
(** [str] parses a path param and returns it as a string. *)

val empty : unit t
(** [empty] matches an empty target. This can be used to match against "/". *)

val choice : 'a t list -> 'a t
(** [choice] accepts a list of route parsers and returns the first one that matches. *)

val with_method : (Method.t * 'a t) list -> 'a router
(** [choose] accepts a list of path param parsers and converts them to a router. *)

val match' : 'a t -> string -> 'a option
(** [match'] takes a route parser and runs it against the provided target url. *)

val match_with_method : 'a router -> target:string -> meth:Method.t -> 'a option
(** [match_with_method] is used to run the router. It accepts a target url string, HTTP method verb
    a request of any type (which is forwarded as the last parameter to the handler functions).
    If a route matches it runs the attached handler and returns the result.
*)

module Infix : sig
  val ( <*> ) : ('a -> 'b) t -> 'a t -> 'b t
  val ( </> ) : ('a -> 'b) t -> 'a t -> 'b t
  val ( <$> ) : ('a -> 'b) -> 'a t -> 'b t
  val ( *> ) : 'a t -> 'b t -> 'b t
  val ( <* ) : 'a t -> 'b t -> 'a t
  val ( <$ ) : 'a -> 'b t -> 'a t
end

module Util : sig
  val split_path : string -> string list
end
