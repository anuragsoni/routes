module Routes_private = struct
  module Util = Util
end

module Map = Stdcompat.Map

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

  let compare = compare
end

module MethodMap = Map.Make (Method)

type 'a t = 'a Parser.t
type 'a router = 'a t list MethodMap.t

let choice = Parser.choice

let with_method routes =
  List.fold_left
    (fun acc (meth, route) ->
      MethodMap.update
        meth
        (fun t ->
          match t with
          | None -> Some [ route ]
          | Some rs -> Some (route :: rs))
        acc)
    MethodMap.empty
    routes
;;

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
      | r :: rs ->
        (match Parser.parse r params with
        | Some (r, []) -> Some r
        | _ -> route' rs)
    in
    match MethodMap.find_opt meth routes with
    | None -> None
    | Some rs -> route' rs)
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
