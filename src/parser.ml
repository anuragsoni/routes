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

let rec combine_routes : type a. a t -> a t -> a t =
 fun t1 t2 ->
  match t1, t2 with
  | SkipLeft (Match w1, f1), SkipLeft (Match w2, f2) when w1 = w2 ->
    (match f1, f2 with
    | Choice c1, Choice c2 -> SkipLeft (Match w1, Choice (List.concat [ c1; c2 ]))
    | _ -> SkipLeft (Match w1, combine_routes f1 f2))
  | _, _ -> Choice [ t1; t2 ]
;;

let choice ps =
  match ps with
  | [] -> Choice []
  | p :: ps -> List.fold_left (fun acc r -> combine_routes acc r) p ps
;;

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

let bool_of_string = function
  | "true" -> Some true
  | "false" -> Some false
  | _ -> None
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
  | Bool -> verify bool_of_string params
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
