open Astring

module Fn = struct
  let id x = x
  let compose f g x = f (g x)
end

module RouterState = struct
  type ('req, 'meth) state =
    { req : 'req
    ; parser_state : Parse.t
    ; meth : 'meth
    }

  let get_request t = t.req
end

open RouterState

let init req target meth =
  let parser_state = Parse.init target in
  { req; parser_state; meth }
;;

type ('req, 'res, 'meth) route = ('req, 'meth) state -> 'res option

let s word state =
  match Parse.parse_param state.parser_state with
  | None -> None
  | Some (w, p') when w = word -> Some ({ state with parser_state = p' }, Fn.id)
  | _ -> None
;;

(* TODO (anuragsoni): This should probably be the default matcher before a handler is called.
   We should perform exact match by default and make the user opt-in to "starts-with" matches. *)
let empty state =
  if Parse.is_finished state.parser_state then Some (state, Fn.id) else None
;;

let anything state = Some (state, Fn.id)

let method' (m : 'meth) state =
  match state with
  | { meth; _ } when m = meth -> Some (state, Fn.id)
  | _ -> None
;;

let extract_param ~f state =
  match Parse.bind ~f state.parser_state with
  | None -> None
  | Some (r, p) -> Some ({ state with parser_state = p }, fun k -> k r)
;;

let str state =
  match Parse.parse_param state.parser_state with
  | None -> None
  | Some (r, p) -> Some ({ state with parser_state = p }, fun k -> k r)
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
