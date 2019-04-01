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

type ('req, 'res, 'meth) route = ('req, 'meth) state -> 'res option option

let path s state =
  match state with
  | r, y :: ys, m when y = s -> Some ((r, ys, m), Fn.id)
  | _ -> None
;;

let non_empty state =
  match state with
  | _, [], _ -> Some (state, Fn.id)
  | _ -> None
;;

let anything state = Some (state, Fn.id)

let method' (m : 'meth) state =
  match state with
  | _, _, m' when m = m' -> Some (state, Fn.id)
  | _ -> None
;;

let str state =
  match state with
  | r, x' :: xs, m -> Some ((r, xs, m), fun k -> k x')
  | _ -> None
;;

let int (r, params, m) =
  match params with
  | [] -> None
  | x :: xs ->
    (match int_of_string_opt x with
    | Some n -> Some ((r, xs, m), fun k -> k n)
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
  | Some ((r, path', m), k) -> Some (Some (k (handle (r, path', m))))
;;

let route paths =
  let rec route' req = function
    | [] -> None
    | x :: xs ->
      (match x req with
      | None -> route' req xs
      | Some action ->
        (match action with
        | None -> route' req xs
        | Some resp -> Some resp))
  in
  fun req -> route' req paths
;;
