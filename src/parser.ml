type 'a pattern =
  { of_string : string -> 'a option
  ; label : string
  }

type 'a t =
  | Return : 'a -> 'a t
  | Empty : unit t
  | Match : string -> unit t
  | CaptureAll : string t
  | Capture : 'a pattern -> 'a t
  | Apply : ('a -> 'b) t * 'a t -> 'b t
  | SkipLeft : 'a t * 'b t -> 'b t
  | SkipRight : 'a t * 'b t -> 'a t

let pattern of_string label = Capture { of_string; label }

module R = Router
module K = R.Key

let get_patterns route =
  let rec aux : type a. a t -> (string * R.Key.t) list -> (string * R.Key.t) list =
   fun t acc ->
    match t with
    | Return _ -> acc
    | Empty -> acc
    | Capture { label; _ } -> (label, K.PCapture) :: acc
    | CaptureAll -> ("<anything>", K.PAll) :: acc
    | Match w -> (w, K.PMatch w) :: acc
    | SkipLeft (l, r) ->
      let l = aux l acc in
      let r' = aux r [] in
      List.concat [ l; r' ]
    | SkipRight (l, r) ->
      let l = aux l acc in
      let r' = aux r [] in
      List.concat [ l; r' ]
    | Apply (l, r) ->
      let l = aux l acc in
      let r' = aux r [] in
      List.concat [ l; r' ]
  in
  aux route []
;;

let s x = Match x
let empty = Empty
let capture_all = CaptureAll
let return x = Return x
let apply f t = Apply (f, t)

module Infix = struct
  let ( <*> ) f t = Apply (f, t)
  let ( </> ) f t = Apply (f, t)
  let ( <$> ) f p = Apply (return f, p)
  let ( *> ) x y = SkipLeft (x, y)
  let ( <* ) x y = SkipRight (x, y)
  let ( <$ ) f t = SkipLeft (t, return f)
end

let verify f params =
  match params with
  | [] -> None
  | p :: ps ->
    (match f p with
    | None -> None
    | Some r -> Some (r, ps))
;;

let rec strip_route : type a. a t -> a t =
 fun t ->
  match t with
  | SkipLeft (_, r) -> strip_route r
  | SkipRight (l, _) -> strip_route l
  | Apply (f, t) -> Apply (strip_route f, strip_route t)
  | _ -> t
;;

let rec parse : type a. a t -> string list -> (a * string list) option =
 fun t params ->
  match t with
  | Return x -> Some (x, params)
  | Empty ->
    (match params with
    | [] -> Some ((), params)
    | _ -> None)
  | Match s -> verify (fun w -> if String.compare w s = 0 then Some () else None) params
  | Capture { of_string; _ } -> verify of_string params
  | CaptureAll ->
    (match params with
    | [] -> Some ("", [])
    | p :: ps -> Some (p, ps))
  | Apply (f, t) ->
    (match parse f params with
    | None -> None
    | Some (f, params) ->
      (match parse t params with
      | None -> None
      | Some (t, params) -> Some (f t, params)))
  | SkipLeft (a, b) ->
    (match parse a params with
    | None -> None
    | Some (_, rest) -> parse b rest)
  | SkipRight (a, b) ->
    (match parse a params with
    | None -> None
    | Some (a', rest) ->
      (match parse b rest with
      | None -> None
      | Some (_, rest) -> Some (a', rest)))
;;
