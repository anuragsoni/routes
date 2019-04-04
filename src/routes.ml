open Astring

module Fn = struct
  let id x = x
  let compose f g x = f (g x)
end

module RouterState = struct
  type ('req, 'meth) state =
    { req : 'req
    ; unvisited : String.Sub.t list
    ; meth : 'meth
    }

  let get_request t = t.req
end

open RouterState

let split_paths target =
  let is_slash x = x = '/' in
  let rec loop rest acc =
    let head, tail = String.Sub.span ~sat:(fun x -> not (is_slash x)) rest in
    if String.Sub.is_empty tail
    then if String.Sub.is_empty head then List.rev acc else List.rev (head :: acc)
    else loop (String.Sub.with_range ~first:1 tail) (head :: acc)
  in
  match target with
  | "" -> [], String.Sub.empty
  | _ ->
    let target', query = String.Sub.span ~sat:(fun x -> x <> '?') (String.sub target) in
    if String.Sub.is_empty target'
    then [], query
    else (
      match String.Sub.get target' 0 with
      | '/' -> loop (String.Sub.with_range ~first:1 target') [], query
      | _ -> loop target' [], query)
;;

let init req target meth =
  (* TODO (anuragsoni): parse query params and make them available to handlers via RouterState *)
  let unvisited, _query = split_paths target in
  { req; unvisited; meth }
;;

type ('req, 'res, 'meth) route = ('req, 'meth) state -> 'res option

let s word state =
  match state with
  | { req; unvisited = y :: ys; meth } when String.Sub.to_string y = word ->
    Some ({ req; unvisited = ys; meth }, Fn.id)
  | _ -> None
;;

(* TODO (anuragsoni): This should probably be the default matcher before a handler is called.
   We should perform exact match by default and make the user opt-in to "starts-with" matches. *)
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

let boolean { req; unvisited = params; meth } =
  match params with
  | [] -> None
  | x :: xs ->
    (match String.Sub.to_bool x with
    | None -> None
    | Some b -> Some ({ req; unvisited = xs; meth }, fun k -> k b))
;;

let int32 { req; unvisited = params; meth } =
  match params with
  | [] -> None
  | x :: xs ->
    (match String.Sub.to_int32 x with
    | None -> None
    | Some i -> Some ({ req; unvisited = xs; meth }, fun k -> k i))
;;

let int64 { req; unvisited = params; meth } =
  match params with
  | [] -> None
  | x :: xs ->
    (match String.Sub.to_int64 x with
    | None -> None
    | Some i -> Some ({ req; unvisited = xs; meth }, fun k -> k i))
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
  | Some (state', k) -> Some (k (handle state'))
;;

let match_with_state ~state paths =
  let rec route' r = function
    | [] -> None
    | x :: xs ->
      (match x r with
      | None -> route' r xs
      | Some resp -> Some resp)
  in
  route' state paths
;;

let match' ~req ~target ~meth paths =
  let req' = init req target meth in
  match_with_state ~state:req' paths
;;
