type 'a pattern =
  { of_string : string -> 'a option
  ; label : string
  }

type 'a t =
  | Return : 'a -> 'a t
  | Empty : unit t
  | Match : string -> unit t
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
let int = pattern int_of_string_opt "<int>"
let int32 = pattern Int32.of_string_opt "<int32>"
let int64 = pattern Int64.of_string_opt "<int64>"
let bool = pattern bool_of_string_opt "<bool>"
let str = pattern (fun x -> Some x) "<string>"
let empty = Empty
let return x = Return x

let rec skip_left : type a b. a t -> b t -> b t =
 fun p1 p2 ->
  match p1 with
  | SkipLeft (a, b) -> SkipLeft (a, skip_left b p2)
  | _ -> SkipLeft (p1, p2)
;;

let rec apply : type a b. (a -> b) t -> a t -> b t =
 fun f t ->
  match f, t with
  | (Return _ as f'), SkipLeft (p, r) -> SkipLeft (p, apply f' r)
  | SkipLeft (p1, f), _ -> skip_left p1 (apply f t)
  | _, SkipRight (p1, p2) -> SkipRight (apply f p1, p2)
  | _ -> Apply (f, t)
;;

module Infix = struct
  let ( <*> ) = apply
  let ( </> ) = apply
  let ( <$> ) f p = apply (return f) p
  let ( *> ) x y = skip_left x y
  let ( <* ) x y = SkipRight (x, y)
  let ( <$ ) f t = skip_left t (return f)
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
