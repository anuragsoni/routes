module Routes_private = struct
  module Util = Util
end

module Method = struct
  type t =
    [ `GET
    | `HEAD
    | `POST
    | `PUT
    | `DELETE
    | `CONNECT
    | `OPTIONS
    | `TRACE
    ]

  let to_int = function
    | `GET -> 1
    | `HEAD -> 2
    | `POST -> 3
    | `PUT -> 4
    | `DELETE -> 5
    | `CONNECT -> 6
    | `OPTIONS -> 7
    | `TRACE -> 8
  ;;
end

type 'a t = 'a Parser.t

module R = struct
  type 'a t =
    { routes : 'a Parser.t Router.t array
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
  let a = Array.make 9 Router.empty in
  List.iter
    (fun (m, r) ->
      let idx = Method.to_int m in
      let current_routes = a.(idx) in
      let patterns = Parser.get_patterns r in
      a.(idx) <- Router.add patterns (Parser.strip_route r) current_routes)
    routes;
  R.create (Util.split_path ignore_trailing_slash) a
;;

let one_of ?(ignore_trailing_slash = true) routes =
  let routes = List.rev routes in
  let a = Array.make 9 Router.empty in
  let r =
    List.fold_left
      (fun acc r ->
        let patterns = Parser.get_patterns r in
        Router.add patterns (Parser.strip_route r) acc)
      Router.empty
      routes
  in
  a.(0) <- r;
  R.create (Util.split_path ignore_trailing_slash) a
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

let match' { R.routes; url_split } target = run_router routes.(0) (url_split target)

let match_with_method { R.routes; url_split } ~target ~meth =
  let idx = Method.to_int meth in
  run_router routes.(idx) (url_split target)
;;
