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
type 'a router = 'a t Router.t array

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

let with_method routes =
  let a = Array.make 9 Router.empty in
  List.iter
    (fun (m, r) ->
      let idx = Method.to_int m in
      let current_routes = a.(idx) in
      let patterns = List.concat (Parser.get_actions r) in
      a.(idx) <- Router.add patterns (Parser.strip_route r) current_routes)
    routes;
  a
;;

let one_of routes =
  let r =
    List.fold_left
      (fun acc r ->
        let patterns = List.concat (Parser.get_actions r) in
        Router.add patterns (Parser.strip_route r) acc)
      Router.empty
      routes
  in
  Array.make 1 r
;;

let run_route routes params =
  match Parser.parse routes params with
  | Some (r, []) -> Some r
  | _ -> None
;;

let run_trie t params =
  let routes, params' = Router.feed_params t params in
  run_route (Parser.choice routes) params'
;;

let match' routes target =
  if String.length target = 0
  then None
  else (
    let params = Util.split_path target in
    run_trie routes.(0) params)
;;

let match_with_method routes ~target ~meth =
  if String.length target = 0
  then None
  else (
    let params = Util.split_path target in
    let idx = Method.to_int meth in
    run_trie routes.(idx) params)
;;
