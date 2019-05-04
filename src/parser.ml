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

let return x = Return x

let apply : type a b. (a -> b) t -> a t -> b t =
  fun f t -> match t with
    | SkipLeft (p1, p2) -> SkipLeft (p1, Apply (f, p2))
    | SkipRight (p1, p2) -> SkipRight (Apply (f, p1), p2)
    | _ -> Apply (f, t)

let s x = Match x
let int = Int
let int32 = Int32
let int64 = Int64
let bool = Bool
let str = Str
let empty = Empty
let choice ps = Choice ps

module Infix = struct
  let ( <*> ) = apply
  let ( </> ) = apply
  let ( <$> ) f p = apply (return f) p
  let ( *> ) x y = SkipLeft (x, y)
  let ( <* ) x y = SkipRight (x, y)
  let ( <$ ) f t = SkipLeft (t, return f)
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
