open Astring

type t = { unvisited : String.t list }

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

let init target =
  (* TODO (anuragsoni): parse query params and make them available to handlers via RouterState *)
  let unvisited, _query = split_paths target in
  { unvisited }
;;

let parse_param state =
  match state.unvisited with
  | [] -> None
  | x :: xs' -> Some (x, { unvisited = xs' })
;;

let is_finished state = state.unvisited = []

let bind ~f state =
  match parse_param state with
  | None -> None
  | Some (p, state') ->
    (match f p with
    | None -> None
    | Some w' -> Some (w', state'))
;;
