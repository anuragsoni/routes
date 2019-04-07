module Fn = struct
  let id x = x
  let compose f g x = f (g x)
end

module Method = struct
  type t =
    [ `GET
    | `HEAD
    | `POST
    | `PUT
    | `DELETE
    | `CONNECT
    | `OPTION
    | `TRACE
    | `PATCH
    ]

  let to_string = function
    | `GET -> "GET"
    | `HEAD -> "HEAD"
    | `POST -> "POST"
    | `PUT -> "PUT"
    | `DELETE -> "DELETE"
    | `CONNECT -> "CONNECT"
    | `OPTION -> "OPTION"
    | `TRACE -> "TRACE"
    | `PATCH -> "PATCH"
  ;;

  let of_string = function
    | "GET" -> Some `GET
    | "HEAD" -> Some `HEAD
    | "POST" -> Some `POST
    | "PUT" -> Some `PUT
    | "DELETE" -> Some `DELETE
    | "CONNECT" -> Some `CONNECT
    | "OPTION" -> Some `OPTION
    | "TRACE" -> Some `TRACE
    | "PATCH" -> Some `PATCH
    | _ -> None
  ;;
end

module RouterState = struct
  type 'req t =
    { req : 'req
    ; unvisited : Astring.String.Sub.t
    ; meth : Method.t
    }

  let create req unvisited meth = { req; unvisited; meth }
  let get_request t = t.req
end

type ('a, 'b) t =
  | End : (unit -> 'a, 'a) t
  | S : string * ('a, 'b) t -> ('a, 'b) t
  | Meth : Method.t * ('a, 'b) t -> ('a, 'b) t
  | Int : ('a, 'b) t -> (int -> 'a, 'b) t
  | Int32 : ('a, 'b) t -> (int32 -> 'a, 'b) t
  | Int64 : ('a, 'b) t -> (int64 -> 'a, 'b) t
  | Bool : ('a, 'b) t -> (bool -> 'a, 'b) t
  | Str : ('a, 'b) t -> (string -> 'a, 'b) t

let int r = Int r
let int32 r = Int32 r
let int64 r = Int64 r
let str r = Str r
let bool r = Bool r
let stop = End
let s w r = S (w, r)
let method' m r = Meth (m, r)
let ( </> ) m1 m2 r = m1 @@ s "/" @@ m2 r

(* Based on https://drup.github.io/2016/08/02/difflists/ *)
let rec ksprintf : type a b. (string -> b) -> (a, b) t -> a =
 fun k -> function
  | End -> fun () -> k ""
  | S (const, fmt) -> ksprintf (fun s -> k @@ String.concat "" [ const; s ]) fmt
  | Meth (_, fmt) -> ksprintf (fun _ -> k "") fmt
  | Str fmt ->
    let f s = ksprintf (fun str -> k @@ String.concat "" [ s; str ]) fmt in
    f
  | Int fmt ->
    let f s = ksprintf (fun str -> k @@ String.concat "" [ string_of_int s; str ]) fmt in
    f
  | Int32 fmt ->
    let f s =
      ksprintf (fun str -> k @@ String.concat "" [ Int32.to_string s; str ]) fmt
    in
    f
  | Int64 fmt ->
    let f s =
      ksprintf (fun str -> k @@ String.concat "" [ Int64.to_string s; str ]) fmt
    in
    f
  | Bool fmt ->
    let f s =
      ksprintf (fun str -> k @@ String.concat "" [ string_of_bool s; str ]) fmt
    in
    f
;;

let print_route fmt = ksprintf (fun x -> x) (fmt End)

let target_consumed t =
  let open Astring in
  if String.Sub.length t > 1
  then false
  else String.Sub.is_empty t || String.Sub.get t 0 = '/'
;;

let runroute fmt handler meth target =
  let rec match_target : type a b.
      (a, b) t -> a -> Astring.String.Sub.t -> (b * Astring.String.Sub.t) option
    =
   fun t f s ->
    match t with
    | End -> if target_consumed s then Some (f (), s) else None
    | S (x, fmt) ->
      (match Parse.drop_prefix x s with
      | None -> None
      | Some (_, rest) -> match_target fmt f rest)
    | Meth (m', fmt) -> if m' = meth then match_target fmt f s else None
    | Int fmt ->
      (match (Parse.filter_map ~f:int_of_string_opt Parse.take_token) s with
      | None -> None
      | Some (i, rest') -> match_target fmt (f i) rest')
    | Int32 fmt ->
      (match (Parse.filter_map ~f:Int32.of_string_opt Parse.take_token) s with
      | None -> None
      | Some (i, rest') -> match_target fmt (f i) rest')
    | Int64 fmt ->
      (match (Parse.filter_map ~f:Int64.of_string_opt Parse.take_token) s with
      | None -> None
      | Some (i, rest') -> match_target fmt (f i) rest')
    | Str fmt ->
      (match Parse.take_token s with
      | None -> None
      | Some (w, rest') -> match_target fmt (f w) rest')
    | Bool fmt ->
      (match (Parse.filter_map ~f:bool_of_string_opt Parse.take_token) s with
      | None -> None
      | Some (b, rest') -> match_target fmt (f b) rest')
  in
  match_target fmt handler target
;;

let ( ==> ) route handler = runroute (route End) handler

let match' paths ~req:_ ~target ~meth =
  let open Astring in
  if String.is_empty target
  then None
  else (
    let target' = String.sub target in
    let target' = match String.Sub.get target' 0 with
      | '/' -> String.Sub.tail target'
      | _ -> target'
    in
    let rec route' = function
      | [] -> None
      | p :: ps ->
        (match p meth target' with
        | None -> route' ps
        | Some (r, _) -> Some r)
    in
    route' paths)
;;
