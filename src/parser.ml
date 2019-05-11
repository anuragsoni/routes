type 'a t =
  | Return : 'a -> 'a t
  | Empty : unit t
  | Match : string -> unit t
  | Apply : ('a -> 'b) t * 'a t -> 'b t
  | SkipLeft : 'a t * 'b t -> 'b t
  | SkipRight : 'a t * 'b t -> 'a t
  | Choice : 'a t list -> 'a t
  | Int : int t
  | Int32 : int32 t
  | Int64 : int64 t
  | Bool : bool t
  | Str : string t

module R = Router
module K = R.Key

let get_actions route =
  let rec aux : type a. a t -> R.Key.t list list -> R.Key.t list list =
   fun t acc ->
    match t with
    | Return _ -> acc
    | Empty -> acc
    | Int -> List.map (fun r -> K.PCapture :: r) acc
    | Int32 -> List.map (fun r -> K.PCapture :: r) acc
    | Int64 -> List.map (fun r -> K.PCapture :: r) acc
    | Bool -> List.map (fun r -> K.PCapture :: r) acc
    | Str -> List.map (fun r -> K.PCapture :: r) acc
    | Match w -> List.map (fun r -> K.PMatch w :: r) acc
    | SkipLeft (l, r) ->
      let l = aux l acc in
      let r' = aux r [ [] ] in
      List.concat (List.map (fun r -> List.map (fun r' -> List.concat [ r'; r ]) l) r')
    | SkipRight (l, r) ->
      let l = aux l acc in
      let r' = aux r [ [] ] in
      List.concat (List.map (fun r -> List.map (fun r' -> List.concat [ r'; r ]) l) r')
    | Apply (l, r) ->
      let l = aux l acc in
      let r' = aux r [ [] ] in
      List.concat (List.map (fun r -> List.map (fun r' -> List.concat [ r'; r ]) l) r')
    | Choice ps ->
      let rs = List.concat (List.map (fun r -> aux r [ [] ]) ps) in
      let q = List.concat (List.map (fun r -> List.map (fun r' -> r @ r') acc) rs) in
      q
  in
  aux route [ [] ]
;;

let s x = Match x
let int = Int
let int32 = Int32
let int64 = Int64
let bool = Bool
let str = Str
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

let choice ps = Choice ps

module Infix = struct
  let ( <*> ) = apply
  let ( </> ) = apply
  let ( <$> ) f p = apply (return f) p
  let ( *> ) x y = skip_left x y
  let ( <* ) x y = SkipRight (x, y)
  let ( <$ ) f t = skip_left t (return f)
  let ( <|> ) p1 p2 = choice [ p1; p2 ]
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
  | Choice rs -> Choice (List.map strip_route rs)
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
  | Int -> verify int_of_string_opt params
  | Int32 -> verify Int32.of_string_opt params
  | Int64 -> verify Int64.of_string_opt params
  | Bool -> verify bool_of_string_opt params
  | Str -> verify (fun w -> Some w) params
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
  | Choice ps ->
    (match ps with
    | [] -> None
    | p :: ps ->
      (match parse p params with
      | None -> parse (Choice ps) params
      | res -> res))
;;
