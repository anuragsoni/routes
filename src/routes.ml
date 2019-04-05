open Astring

module Fn = struct
  let id x = x
  let compose f g x = f (g x)
end

module RouterState = struct
  type ('req, 'meth) state =
    { req : 'req
    ; unvisited : String.t list
    ; meth : 'meth
    }

  let get_request t = t.req
end

open RouterState

let split_paths target =
  let is_slash x = x = '/' in
  let rec loop rest acc =
    let head, tail = String.span ~sat:(fun x -> not (is_slash x)) rest in
    if String.is_empty tail
    then if String.is_empty head then List.rev acc else List.rev (head :: acc)
    else loop (String.with_range ~first:1 tail) (head :: acc)
  in
  match target with
  | "" -> [], String.empty
  | _ ->
    let target', query = String.span ~sat:(fun x -> x <> '?') target in
    if String.is_empty target'
    then [], query
    else (
      match target'.[0] with
      | '/' -> loop (String.with_range ~first:1 target') [], query
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
  | { unvisited = y :: ys; _ } when String.equal y word ->
    Some ({ state with unvisited = ys }, Fn.id)
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

let extract_param ~f ({ unvisited = params; _ } as state) =
  match params with
  | [] -> None
  | x :: xs ->
    (match f x with
    | None -> None
    | Some n -> Some ({ state with unvisited = xs }, fun k -> k n))
;;

let str state =
  match state with
  | { unvisited = x' :: xs; _ } -> Some ({ state with unvisited = xs }, fun k -> k x')
  | _ -> None
;;

let int state = extract_param ~f:String.to_int state
let boolean state = extract_param ~f:String.to_bool state
let int32 state = extract_param ~f:String.to_int32 state
let int64 state = extract_param ~f:String.to_int64 state

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
