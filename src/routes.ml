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

module RKey = struct
  type t = string * int

  let compare (t1 : string * int) t2 = compare t2 t1
end

module MethodSet = Set.Make (Method)
module RMap = Map.Make (RKey)

type 'a t =
  | Return : 'a -> 'a t
  | Empty : unit t
  | Match : string -> unit t
  | Apply : ('a -> 'b) t * 'a t -> 'b t
  | Int : int t
  | Str : string t

type 'a route = MethodSet.t * int * 'a t
type 'a route' = MethodSet.t * 'a t
type 'a router = 'a route' list RMap.t

let return x = Return x
let apply f t = Apply (f, t)
let fmap ~f t = apply (return f) t
let s x = Match x
let int = Int
let str = Str
let empty = Empty

let rec dependencies : type a. a t -> int =
 fun t ->
  match t with
  | Return _ -> 0
  | Match _ -> 1
  | Empty -> 0
  | Int -> 1
  | Str -> 1
  | Apply (f, t) ->
    let a = dependencies f in
    let b = dependencies t in
    a + b
;;

let rec first : type a. a t -> string =
 fun t ->
  match t with
  | Return _ -> ""
  | Empty -> ""
  | Match w -> w
  | Int -> ""
  | Str -> ""
  | Apply (f, t) ->
    let a = first f in
    if a <> "" then a else first t
;;

let rec parse : type a. a t -> string list -> (a * string list) option =
 fun t params ->
  match t with
  | Return x -> Some (x, params)
  | Empty ->
    (match params with
    | [] -> Some ((), params)
    | _ -> None)
  | Match s ->
    (match params with
    | [] -> None
    | p :: ps when p = s -> Some ((), ps)
    | _ -> None)
  | Int ->
    (match params with
    | [] -> None
    | p :: ps ->
      (match int_of_string_opt p with
      | None -> None
      | Some r -> Some (r, ps)))
  | Str ->
    (match params with
    | [] -> None
    | p :: ps -> Some (p, ps))
  | Apply (f, t) ->
    (match parse f params with
    | None -> None
    | Some (f, params) ->
      (match parse t params with
      | None -> None
      | Some (t, params) -> Some (f t, params)))
;;

let choose routes =
  List.fold_left
    (fun acc (methods, route) ->
      let f = first route in
      let methods =
        List.fold_left (fun acc m -> MethodSet.add m acc) MethodSet.empty methods
      in
      let new_route = methods, route in
      RMap.update
        (f, dependencies route)
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
    let param_len = List.length params in
    let rec route' = function
      | [] -> None
      | (methods, r) :: rs when method_matches methods meth ->
        (match parse r params with
        | Some (r, []) -> Some (r req)
        | _ -> route' rs)
      | _ -> None
    in
    match params with
    | [] -> None
    | p :: _ ->
      (match RMap.find_opt (p, param_len) routes with
      | None ->
        (match RMap.find_opt ("", param_len) routes with
        | None -> None
        | Some rs -> route' rs)
      | Some rs -> route' rs))
;;

module Infix = struct
  let ( <*> ) = apply
  let ( </> ) = apply
  let ( >>| ) t f = fmap t ~f
  let ( <$> ) f = fmap ~f
  let ( *> ) x y = (fun _ y -> y) <$> x <*> y
  let ( <* ) x y = (fun x _ -> x) <$> x <*> y
  let ( <$ ) f t = return f <* t
end
