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
    | `Other of string
    ]
end

type 'a t = 'a Parser.t
type 'a router = (Method.t * 'a t) list

let choice = Parser.choice
let with_method routes = routes

let match' routes target =
  if String.length target = 0
  then None
  else (
    let params = Util.split_path target in
    match Parser.parse routes params with
    | Some (r, []) -> Some r
    | _ -> None)
;;

let match_with_method routes ~target ~meth =
  if String.length target = 0
  then None
  else (
    let params = Util.split_path target in
    let rec route' = function
      | [] -> None
      | (m, r) :: rs ->
        if meth = m
        then (
          match Parser.parse r params with
          | Some (r, []) -> Some r
          | _ -> route' rs)
        else route' rs
    in
    route' routes)
;;

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
