open Astring

module Fn = struct
  let id x = x
  let compose f g x = f (g x)
end

type ('req, 'meth) state =
  { req : 'req
  ; unvisited : String.Sub.t list
  ; meth : 'meth
  }

let split_paths target =
  let is_slash x = x = '/' in
  let rec loop rest acc =
    let head, tail = String.Sub.span ~sat:(fun x -> not (is_slash x)) rest in
    if String.Sub.is_empty tail
    then
      if String.Sub.is_empty head
      then List.rev acc, tail
      else List.rev (head :: acc), tail
    else loop (String.Sub.drop ~sat:is_slash tail) (head :: acc)
  in
  match target with
  | "" -> [], String.Sub.empty
  | _ ->
    (match target.[0] with
    | '/' -> loop (String.Sub.v ~start:1 target) []
    | _ -> loop (String.sub target) [])
;;

let init req target meth =
  let unvisited, _rest = split_paths target in
  { req; unvisited; meth }
;;

type ('req, 'res, 'meth) route = ('req, 'meth) state -> 'res option

let s word state =
  match state with
  | { req; unvisited = y :: ys; meth } when String.Sub.to_string y = word ->
    Some ({ req; unvisited = ys; meth }, Fn.id)
  | _ -> None
;;

let empty state =
  match state with
  | { unvisited = []; _ } -> Some (state, Fn.id)
  | _ -> None
;;

let anything state = Some (state, Fn.id)

let method' (m : 'meth) state =
  match state with
  | { meth; _ } when m = meth -> Some (state, Fn.id)
  | _ -> None
;;

let str state =
  match state with
  | { req; unvisited = x' :: xs; meth } ->
    Some ({ req; unvisited = xs; meth }, fun k -> k (String.Sub.to_string x'))
  | _ -> None
;;

let int { req; unvisited = params; meth } =
  match params with
  | [] -> None
  | x :: xs ->
    (match String.Sub.to_int x with
    | Some n -> Some ({ req; unvisited = xs; meth }, fun k -> k n)
    | None -> None)
;;

let ( </> ) m1 m2 state =
  match m1 state with
  | None -> None
  | Some (r', k) ->
    (match m2 r' with
    | None -> None
    | Some (r'', k') -> Some (r'', Fn.compose k' k))
;;

let ( ==> ) mat handle state =
  match mat state with
  | None -> None
  | Some ({ req; _ }, k) -> Some (k (handle req))
;;

let match' ~req ~target ~meth paths =
  let req' = init req target meth in
  let rec route' r = function
    | [] -> None
    | x :: xs ->
      (match x r with
      | None -> route' r xs
      | Some resp -> Some resp)
  in
  route' req' paths
;;
