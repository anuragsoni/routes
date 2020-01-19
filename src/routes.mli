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
type ('a, 'b) req
type 'b route

val int : ('a, 'b) path -> (int -> 'a, 'b) path
val str : ('a, 'b) path -> (string -> 'a, 'b) path
val bool : ('a, 'b) path -> (bool -> 'a, 'b) path
val s : string -> ('a, 'b) path -> ('a, 'b) path
val ( / ) : (('a, 'b) path -> 'c) -> ('d -> ('a, 'b) path) -> 'd -> 'c
val ( @--> ) : ('a, 'b) req -> 'a -> 'b route
val meth' : Method.t -> (('a, 'a) path -> ('b, 'c) path) -> ('b, 'c) req
val match' : 'a route list -> string -> 'a option
val sprintf : ('a, string) path -> 'a
val pp : (Format.formatter -> ('a, 'b) path -> unit[@ocaml.toplevel_printer])
val nil : ('a, 'a) path
