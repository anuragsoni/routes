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

type ('a, 'b) path
(** [path] represents a sequence of path parameter patterns that are expected in a route. *)

type 'b route
(** [route] is a combination of a path sequence, with a function that will be
    called on a successful match. When a path sequence matches, the patterns
    that are extracted are forwarded to said function with the types that the user
    defined.

    Example:

    {[
      let route () = Routes.(s "foo" / str / int /? nil @-->
        (fun (a : string) (b : int) ->
            Printf.sprintf "%s %d" a b))
    ]}

*)

type 'b router
(** [router] is a collection of multiple routes. It transforms a list of routes
    into a trie like structure, that is then used for matching an input target url.
    It works for routes that are grouped by an HTTP verb and for standalone routes
    that have no HTTP verb attached to it. *)

val int : ('a, 'b) path -> (int -> 'a, 'b) path
(** [int] matches a path segment if it can be successfully coerced into an integer. *)

val int32 : ('a, 'b) path -> (int32 -> 'a, 'b) path
(** [int32] matches a path segment if it can be successfully coerced into a 32 bit integer. *)

val int64 : ('a, 'b) path -> (int64 -> 'a, 'b) path
(** [int64] matches a path segment if it can be successfully coerced into a 64 bit integer. *)

val str : ('a, 'b) path -> (string -> 'a, 'b) path
(** [str] matches any path segment and forwards it as a string. *)

val bool : ('a, 'b) path -> (bool -> 'a, 'b) path
(** [bool] matches a path segment if it can be successfully coerced into a boolean. *)

val s : string -> ('a, 'b) path -> ('a, 'b) path
(** [s word] matches a path segment if it exactly matches [word]. The matched path param is then discarded. *)

val nil : ('a, 'a) path

val pattern
  :  ('c -> string)
  -> (string -> 'c option)
  -> string
  -> ('a, 'b) path
  -> ('c -> 'a, 'b) path
(** [pattern] accepts two functions, one for converting a user provided type to
    a string representation, and another to potentially convert a string to the said type.
    With these two functions, it creates a pattern that can be used for matching a path segment.
    This is useful when there is a need for types that aren't provided out of the box
    by the library.

    Example:

    {[
      type shape =
        | Square
        | Circle

      let shape_of_string = function
        | "square" -> Some Square
        | "circle" -> Some Circle
        | _ -> None

      let shape_to_string = function
        | Square -> "square"
        | Circle -> "circle"

      let shape = Routes.pattern shape_to_string shape_of_string

      (* Now the shape pattern can be used just like any
         of the built in patterns like int, bool etc *)
      let route () = s "shape" / shape / s "create" /? nil
    ]}

*)

val ( / ) : (('a, 'b) path -> 'c) -> ('d -> ('a, 'b) path) -> 'd -> 'c
(** [l / r] joins two path match patterns [l] and [r] into a pattern sequence, parse l followed by parse r.
    Example: If we want to define a route that matches a string followd by
    a constant "foo" and then an integer, we'd use the [/] operator like below:
    {[
      let route () = Routes.(str / s "foo" / int /? nil)
    ]} *)

val ( /? ) : (('a, 'b) path -> 'c) -> ('a, 'b) path -> 'c
(** [l /? r] is used to express the sequence of, parse l followed by parse r and then stop parsing.
    This is used at the end of the route pattern to define how a route should end. The right hand parameter
    [r] should be a pattern definition that cannot be used in further chains joined by [/] (One such operator is [nil]). *)

val ( @--> ) : (unit -> ('a, 'b) path) -> 'a -> 'b route
(** [r @--> h] is used to connect a route pattern [r] to a function [h] that gets called
    if this pattern is successfully matched.*)

val one_of : (Method.t option * 'b route) list -> 'b router
(** [one_of] accepts a list of tuples comprised of an optional HTTP verb and a route definition
    of type ['b route] where 'b is the type that a successful route match will return.

    It transforms the input list of routes into a trie like structure that can later be used
    to perform route matches. *)

val match' : ?meth:Method.t -> 'a router -> target:string -> 'a option
(** [match'] accepts an optional HTTP verb, a router and the target url to match.
    if the HTTP verb is provided, it tries to look for a matching route that was defined
    with the specific HTTP verb provided as input. Otherwise it looks for a route
    that is not associated to any HTTP verb.
*)

val sprintf : (unit -> ('a, string) path) -> 'a
(** [sprintf] takes a route pattern as an input, and returns a string with the result
    of formatting the pattern into a URI path. *)

val ksprintf : (string list -> 'b) -> (unit -> ('a, 'b) path) -> 'a
(** [ksprintf] is the same as [sprintf], but instead of returning a string, it passes
    it to the function provided as the first argument. *)

val pp_route : Format.formatter -> (unit -> ('a, 'b) path) -> unit
(** [pp_route] can be used to pretty-print a route. This can be useful
    to get a human readable output that indicates the kind of pattern
    that a route will match. When creating a custom pattern matcher
    using [pattern], a string label needs to be provided. This label
    is used by [pp_route] when preparing the pretty-print output.

    Example:
    {[
      let r () = Routes.(s "foo" / int / s "add" / bool);;
      Format.asprintf "%a" Routes.pp_route r;;
      -: "foo/:int/add/:bool"
    ]}
*)
