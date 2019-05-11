open Containers

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

  let compare = Pervasives.compare
end

type 'a t = 'a Parser.t

module MethodMap = Map.Make (Method)

type 'a router = ('a t Router.t) MethodMap.t

let choice = Parser.choice
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
  List.fold_left
    (fun acc (m, r) ->
      MethodMap.update
        m
        (fun t ->
          match t with
          | None ->
            let q = Router.empty in
            Some (Router.add (List.concat (Parser.get_actions r)) (Parser.strip_route r) q)
          | Some q ->
            Some (Router.add (List.concat (Parser.get_actions r)) (Parser.strip_route r) q)
          )
        acc)
    MethodMap.empty
    routes
;;

let run_route routes params =
  match Parser.parse routes params with
  | Some (r, []) -> Some r
  | _ -> None
;;

let run_trie t params =
  let routes, params' = Router.feed_params t params in
  run_route (choice routes) params'
;;

let match' routes target =
  if String.length target = 0
  then None
  else (
    let params = Util.split_path target in
    run_route routes params)
;;

let match_with_method routes ~target ~meth =
  if String.length target = 0
  then None
  else (
    let params = Util.split_path target in
    match MethodMap.find_opt meth routes with
    | None -> None
    | Some r -> run_trie r params)
;;
