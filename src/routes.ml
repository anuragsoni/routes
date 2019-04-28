module StringUtils = struct
  let drop_i t i =
    let len = String.length t in
    if i > len then "" else String.sub t i (len - i)
  ;;

  let take_i t i =
    let len = String.length t in
    if i > len then t else String.sub t 0 i
  ;;

  let tail t = drop_i t 1

  let take_while_i t ~f =
    let len = String.length t in
    let rec loop i = if i = len then i else if f t.[i] then loop (i + 1) else i in
    loop 0
  ;;

  let take_while ~f t =
    let i = take_while_i ~f t in
    take_i t i, drop_i t i
  ;;
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

  let compare = compare
end

module MethodSet = Set.Make (Method)
module RMap = Map.Make (String)

type 'a t = 'a Parser.t
type 'a route = MethodSet.t * 'a Parser.t
type 'a router = 'a route list RMap.t

let choose routes =
  List.fold_left
    (fun acc (methods, route) ->
      let f = Parser.first route in
      let methods =
        List.fold_left (fun acc m -> MethodSet.add m acc) MethodSet.empty methods
      in
      let new_route = methods, route in
      RMap.update
        f
        (fun t ->
          match t with
          | None -> Some [ new_route ]
          | Some rs -> Some (new_route :: rs))
        acc)
    RMap.empty
    routes
;;

let method_matches t m = if MethodSet.is_empty t then true else MethodSet.mem m t

let run routes ~target ~meth ~req =
  if String.length target = 0
  then None
  else (
    let target, _ = StringUtils.take_while target ~f:(fun x -> x <> '?') in
    let target' =
      match target.[0] with
      | '/' -> StringUtils.tail target
      | _ -> target
    in
    let params = String.split_on_char '/' target' in
    let rec route' = function
      | [] -> None
      | (methods, r) :: rs when method_matches methods meth ->
        (match Parser.parse r params with
        | Some (r, []) -> Some (r req)
        | _ -> route' rs)
      | _ -> None
    in
    match params with
    | [] -> None
    | p :: _ ->
      (match RMap.find_opt p routes with
      | None ->
        (match RMap.find_opt "" routes with
        | None -> None
        | Some rs -> route' rs)
      | Some rs -> route' rs))
;;

let empty = Parser.empty
let str = Parser.str
let int = Parser.int
let s = Parser.s
let apply = Parser.apply
let return = Parser.return

module Infix = struct
  include Parser.Infix
end
