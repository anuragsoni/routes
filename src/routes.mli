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

module RouterState : sig
  (** This will be comprised of the query params (unparsed for now)
      that were part of the route. *)
  type t

  val query : t -> string
end

(** [path] represents the combination of all path params that are expected in a route. *)
type ('a, 'b) path

(** [route] represents a combination of an optional HTTP method and path parameters. *)
type ('a, 'b) route

(** [sprintf] acceps a [route] that acts like a "format string". It will
    return a function that the user can use to output formatted URLs. *)
val sprintf : ('a, string) route -> 'a

(** [match'] acceps a list of route descriptions, target url and a
    http method. If there is a match it returns the output of the handler
    registered with a route. Otherwise it returns a `None`. *)
val match'
  :  ('a -> Astring.String.sub -> (unit -> 'b) option) list
  -> target:string
  -> meth:'a
  -> ('b * RouterState.t) option

(** [int] will match and extract an integer value that will be forwarded to
    the request handler. *)
val int : ('a, 'b) path -> (int -> 'a, 'b) path

(** [int32] will match and extract a 32 bit integer. *)
val int32 : ('a, 'b) path -> (int32 -> 'a, 'b) path

(** [int64] will match and extract a 64 bit integer. *)
val int64 : ('a, 'b) path -> (int64 -> 'a, 'b) path

(** [str] will match and extract a string value that will be forwarded to
		the request handler. *)
val str : ('a, 'b) path -> (string -> 'a, 'b) path

(** [bool] will match and extract a boolean value. *)
val bool : ('a, 'b) path -> (bool -> 'a, 'b) path

(** [s str] does an exact match on the input string.
    It consumes and discards the string and as a result the handler doesn't
    need to work on the parsed string. If there are no paths left to
    match on given URL, or the match failes, the whole
    route matching fails. *)
val s : string -> ('a, 'b) path -> ('a, 'b) path

(** [</>] is used to connect two path parsers. Ex: str </> int
    will first try and parse a string, followed by an integer.
    If any of the parsers fail, the whole route matching fails. *)
val ( </> ) : (('a, 'b) path -> 'c) -> ('d -> ('a, 'b) path) -> 'd -> 'c

(** [method'] connects an HTTP method to a path parameters, and forms
    a complete route. *)
val method'
  :  Method.t option
  -> ((unit -> 'a, 'a) path -> ('b, 'c) path)
  -> ('b, 'c) route

(** [==>] connects a route matcher to a user provided handler.
    The handler will receive any params that
    were extracted while parsing the route. *)
val ( ==> )
  :  ('a, 'b) route
  -> 'a
  -> Method.t
  -> Astring.String.Sub.t
  -> (unit -> 'b) option
