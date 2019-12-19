(** Typed routing for OCaml.
    [Routes] provides combinators for adding typed routing
    to OCaml applications. The core library will be independent
    of any particular web framework or runtime.
*)

module Method : sig
  type standard =
    [ `GET
    | `HEAD
    | `POST
    | `PUT
    | `DELETE
    | `CONNECT
    | `OPTIONS
    | `TRACE
    ]

  type t =
    [ standard
    | `Other of string
    ]
  (** HTTP methods. This is an optional input for route matching.
      The current types are chosen to be compatible with what Httpaf uses - {{:https://github.com/inhabitedtype/httpaf/blob/c2ee924eaccd2adb2e6aea0b9bc6a0ffe6132723/lib/method.ml} link}. *)

  val pp : Format.formatter -> t -> unit
  (** @since 0.6.0 *)

  val equal : t -> t -> bool
  (** @since 0.6.0 *)

  val compare : t -> t -> int
  (** @since 0.6.0 *)
end

type 'a t
(** ['a t] represents a path parameter of type 'a. *)

type 'a router
(** ['a router] represents the internal router data type, where each route
    can potentially return a value of type 'a .*)

val pattern : (string -> 'a option) -> string -> 'a t
(** [pattern convert label] allows the creation of custom param matchers.
    This allows creating matchers for custom types so the router
    can be extended to use types beyond the ones that ship with the library.

    The provided label will be used when pretty printing routes, or when
    converting a route to a human readable string pattern.

    Example:

    {[
      (* This pattern matches any integer *)
      let int = pattern int_of_string_opt "<int>"

      let bool = pattern bool_of_string_opt "<bool>"
    ]}

    @since 0.6.0 *)

val return : 'a -> 'a t
(** [return v] is a path param parser that always returns v. *)

val apply : ('a -> 'b) t -> 'a t -> 'b t
(** [apply f t]  applies a function f that is wrapped inside
    a ['a t] context to a path param parser.
    f <*> p is the same as f >>= fun f -> map ~f p

    Example:
    {[
      let add = a + b (* int -> int -> int *)

      let add' = return add (* (int -> int -> int) t *)

      apply add' int (* (int -> int) t *)
    ]}

*)

val s : string -> unit t
(** [s word] returns a path parser that matches [word] exactly and then
    discards the result. *)

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

val one_of : ?ignore_trailing_slash:bool -> 'a t list -> 'a router
(** [one_of] accepts a list of route parsers and converts into a router.
    ignore_trailing_slash is a boolean flag that can control whether to keep
    or ignore the trailing slash in the input target url. The default value
    is true. *)

val with_method : ?ignore_trailing_slash:bool -> (Method.t * 'a t) list -> 'a router
(** [with_method] accepts a list of routes + http methods and converts it into a router.
    This will also group methods based on the Http verb. If there are multiple route
    definitions that overlap and are potential matches, the one defined first will be returned.

    ignore_trailing_slash is a boolean flag that can control whether to keep
    or ignore the trailing slash in the input target url. The default value
    is true. *)

val match' : 'a router -> string -> 'a option
(** [match'] runs the router against the provided target url. *)

val match_with_method : 'a router -> target:string -> meth:Method.t -> 'a option
(** [match_with_method] is used to run the router. It accepts a target url string, HTTP method verb
    a request of any type (which is forwarded as the last parameter to the handler functions).
    If a route matches it runs the attached handler and returns the result.
*)

val get_route_patterns : 'a router -> (Method.t * string) list
(** [get_route_patterns] returns a list of human readable route patterns
    that will be matched by a router.

    @since 0.6.0 *)

val pattern_of_route : 'a t -> string
(** [pattern_of_route] convert a route to a human readable string pattern.

    @since 0.6.0 *)

val pp_route : Format.formatter -> 'a t -> unit
  [@@ocaml.toplevel_printer]
(** @since 0.6.0 *)

val pp_router : Format.formatter -> 'a router -> unit
  [@@ocaml.toplevel_printer]
(** @since 0.6.0 *)

module Infix : sig
  val ( <*> ) : ('a -> 'b) t -> 'a t -> 'b t
  (** [<*>] takes a function wrapped inside our parser
      context (created via [return <some function>] ), and a parser.
      It then forwards the value of the parsed result (if parser succeeds) and feeds
      it to the wrapped function. This is the [apply] operator of our
      parser applicative functor. *)

  val ( </> ) : ('a -> 'b) t -> 'a t -> 'b t
  (** [</>] is an alias for [<*>] *)

  val ( <$> ) : ('a -> 'b) -> 'a t -> 'b t
  (** [f <$> p] is sugar for [return f <*> p] *)

  val ( *> ) : unit t -> 'b t -> 'b t
  (** [p1 *> p2] takes two parsers p1 and p2, runs p1, discards its results
      and then returns the result of parser p2. *)

  val ( <* ) : 'a t -> unit t -> 'a t
  (** [p1 <* p2] runs p1 followed by p2. It discards the result of p2 and returns
      the result of p1. *)

  val ( <$ ) : 'a -> unit t -> 'a t
  (** [f <$ p] is sugar for [return f <* p] *)
end

module Routes_private : sig
  module Util : sig
    val split_path : bool -> string -> string list
  end
end
