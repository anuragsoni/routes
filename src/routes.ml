module Fn = struct
  let id x = x
  let compose f g x = f (g x)
end

type ('req, 'meth) state =
  { req : 'req
  ; unvisited : string list
  ; meth : 'meth
  }

let init req target meth =
  let unvisited = List.filter (fun x -> x <> "") (String.split_on_char '/' target) in
  { req; unvisited; meth }
;;

type ('req, 'res, 'meth) route = ('req, 'meth) state -> 'res option

let path s state =
  match state with
  | { req; unvisited = y :: ys; meth } when y = s ->
    Some ({ req; unvisited = ys; meth }, Fn.id)
  | _ -> None
;;

let non_empty state =
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
    Some ({ req; unvisited = xs; meth }, fun k -> k x')
  | _ -> None
;;

let int { req; unvisited = params; meth } =
  match params with
  | [] -> None
  | x :: xs ->
    (match int_of_string_opt x with
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

let route paths =
  let rec route' req = function
    | [] -> None
    | x :: xs ->
      (match x req with
      | None -> route' req xs
      | Some resp -> Some resp)
  in
  fun req -> route' req paths
;;
