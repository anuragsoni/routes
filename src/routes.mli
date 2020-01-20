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
type 'b route
type 'b router

val pattern
  :  ('c -> string)
  -> (string -> 'c option)
  -> ('a, 'b) path
  -> ('c -> 'a, 'b) path

val int : ('a, 'b) path -> (int -> 'a, 'b) path
val int32 : ('a, 'b) path -> (int32 -> 'a, 'b) path
val int64 : ('a, 'b) path -> (int64 -> 'a, 'b) path
val str : ('a, 'b) path -> (string -> 'a, 'b) path
val bool : ('a, 'b) path -> (bool -> 'a, 'b) path
val s : string -> ('a, 'b) path -> ('a, 'b) path
val ( / ) : (('a, 'b) path -> 'c) -> ('d -> ('a, 'b) path) -> 'd -> 'c
val ( /? ) : (('a, 'b) path -> 'c) -> ('a, 'b) path -> 'c
val ( @--> ) : (unit -> ('a, 'b) path) -> 'a -> 'b route
val match' : ?meth:Method.t -> 'a router -> target:string -> 'a option
val sprintf : (unit -> ('a, string) path) -> 'a
val nil : ('a, 'a) path
val one_of : (Method.t option * 'b route) list -> 'b router
