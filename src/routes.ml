module Routes_private = struct
  module Util = Util
end

module Method = struct
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

  let default = `GET

  let to_string = function
    | `GET -> "GET"
    | `HEAD -> "HEAD"
    | `POST -> "POST"
    | `PUT -> "PUT"
    | `DELETE -> "DELETE"
    | `CONNECT -> "CONNECT"
    | `OPTIONS -> "OPTION"
    | `TRACE -> "TRACE"
    | `Other s -> s
  ;;

  let compare m1 m2 = String.compare (to_string m1) (to_string m2)
end

module MethodMap = Map.Make (Method)

type 'a t = 'a Parser.t

module R = struct
  type 'a t =
    { routes : 'a Parser.t Router.t MethodMap.t
    ; url_split : string -> string list
    }

  let create url_split routes = { routes; url_split }
end

type 'a router = 'a R.t

let empty = Parser.empty
let str = Parser.str
let int = Parser.int
let int32 = Parser.int32
let int64 = Parser.int64
let bool = Parser.bool
let s = Parser.s
let apply = Parser.apply
let return = Parser.return

module Infix = struct
  include Parser.Infix
end

let with_method ?(ignore_trailing_slash = true) routes =
  let routes = List.rev routes in
  let f acc (m, r) =
    let current_routes =
      match MethodMap.find_opt m acc with
      | None -> Router.empty
      | Some v -> v
    in
    let patterns = Parser.get_patterns r in
    MethodMap.add m (Router.add patterns (Parser.strip_route r) current_routes) acc
  in
  let map = List.fold_left f MethodMap.empty routes in
  R.create (Util.split_path ignore_trailing_slash) map
;;

let one_of ?(ignore_trailing_slash = true) routes =
  let m = Method.default in
  let routes = List.rev routes in
  let f acc r =
    let current_routes =
      match MethodMap.find_opt m acc with
      | None -> Router.empty
      | Some v -> v
    in
    let patterns = Parser.get_patterns r in
    MethodMap.add m (Router.add patterns (Parser.strip_route r) current_routes) acc
  in
  let map = List.fold_left f MethodMap.empty routes in
  R.create (Util.split_path ignore_trailing_slash) map
;;

let run_route routes params =
  let rec aux routes =
    match routes with
    | [] -> None
    | r :: rs ->
      (match Parser.parse r params with
      | Some (res, []) -> Some res
      | _ -> aux rs)
  in
  aux routes
;;

let run_router t params =
  let routes, params' = Router.feed_params t params in
  run_route routes params'
;;

let match_with_method { R.routes; url_split } ~target ~meth =
  let routes =
    match MethodMap.find_opt meth routes with
    | None -> Router.empty
    | Some v -> v
  in
  run_router routes (url_split target)
;;

let match' r target = match_with_method r ~target ~meth:Method.default
