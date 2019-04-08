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

  let to_string = function
    | `GET -> "GET"
    | `HEAD -> "HEAD"
    | `POST -> "POST"
    | `PUT -> "PUT"
    | `DELETE -> "DELETE"
    | `CONNECT -> "CONNECT"
    | `OPTIONS -> "OPTIONS"
    | `TRACE -> "TRACE"
    | `Other s -> s
  ;;
end

type ('a, 'b) path =
  | End : (unit -> 'a, 'a) path
  | S : string * ('a, 'b) path -> ('a, 'b) path
  | Int : ('a, 'b) path -> (int -> 'a, 'b) path
  | Int32 : ('a, 'b) path -> (int32 -> 'a, 'b) path
  | Int64 : ('a, 'b) path -> (int64 -> 'a, 'b) path
  | Bool : ('a, 'b) path -> (bool -> 'a, 'b) path
  | Str : ('a, 'b) path -> (string -> 'a, 'b) path

and ('a, 'b) route = Route : Method.t option * ('a, 'b) path -> ('a, 'b) route

(* Based on https://drup.github.io/2016/08/02/difflists/ *)
let rec print_params : type a b. (string -> b) -> (a, b) path -> a =
 fun k -> function
  | End -> fun () -> k ""
  | S (const, fmt) -> print_params (fun s -> k @@ String.concat "" [ const; s ]) fmt
  (* | Meth (_, fmt) -> print_params (fun _ -> k "") fmt *)
  | Str fmt ->
    let f s = print_params (fun str -> k @@ String.concat "" [ s; str ]) fmt in
    f
  | Int fmt ->
    let f s =
      print_params (fun str -> k @@ String.concat "" [ string_of_int s; str ]) fmt
    in
    f
  | Int32 fmt ->
    let f s =
      print_params (fun str -> k @@ String.concat "" [ Int32.to_string s; str ]) fmt
    in
    f
  | Int64 fmt ->
    let f s =
      print_params (fun str -> k @@ String.concat "" [ Int64.to_string s; str ]) fmt
    in
    f
  | Bool fmt ->
    let f s =
      print_params (fun str -> k @@ String.concat "" [ string_of_bool s; str ]) fmt
    in
    f

and print_route : type a b. (string -> b) -> (a, b) route -> a =
 fun k -> function
  | Route (m, r) ->
    print_params
      (fun s ->
        match m with
        | None -> k @@ s
        | Some m' -> k @@ String.concat " " [ Method.to_string m'; s ])
      r
;;

let sprintf fmt = print_route (fun x -> x) fmt
let target_consumed t = Astring.String.Sub.is_empty t

let runroute fmt handler meth target =
  let open Astring in
  let rec match_target : type a b.
      (a, b) path -> a -> Astring.String.Sub.t -> (b * Astring.String.Sub.t) option
    =
   fun t f s ->
    match t with
    | End -> if target_consumed s then Some (f (), s) else None
    | S (x, fmt) ->
      (match Parse.drop_prefix x s with
      | None -> None
      | Some (_, rest) -> match_target fmt f rest)
    | Int fmt ->
      (match (Parse.filter_map ~f:String.to_int Parse.take_token) s with
      | None -> None
      | Some (i, rest') -> match_target fmt (f i) rest')
    | Int32 fmt ->
      (match (Parse.filter_map ~f:String.to_int32 Parse.take_token) s with
      | None -> None
      | Some (i, rest') -> match_target fmt (f i) rest')
    | Int64 fmt ->
      (match (Parse.filter_map ~f:String.to_int64 Parse.take_token) s with
      | None -> None
      | Some (i, rest') -> match_target fmt (f i) rest')
    | Str fmt ->
      (match Parse.take_token s with
      | None -> None
      | Some (w, rest') -> match_target fmt (f w) rest')
    | Bool fmt ->
      (match (Parse.filter_map ~f:String.to_bool Parse.take_token) s with
      | None -> None
      | Some (b, rest') -> match_target fmt (f b) rest')
  and match_route : type a b. (a, b) route -> a -> (b * Astring.String.Sub.t) option =
   fun t f ->
    match t with
    | Route (m, r) ->
      (match m with
      | None -> match_target r f target
      | Some m' -> if m' = meth then match_target r f target else None)
  in
  match_route fmt handler
;;

let match' paths ~target ~meth =
  let open Astring in
  if String.is_empty target
  then None
  else (
    let target' = String.sub target in
    let target' =
      match String.Sub.get target' 0 with
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

(* Public api to construct paths *)
let int r = Int r
let int32 r = Int32 r
let int64 r = Int64 r
let str r = Str r
let bool r = Bool r
let s w r = S (w, r)
let ( </> ) m1 m2 r = m1 @@ s "/" @@ m2 r

(* Public api to construct Routes *)
let method' meth r = Route (meth, r End)
let ( ==> ) route handler = runroute route handler
