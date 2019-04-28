type 'a t =
  | Return : 'a -> 'a t
  | Empty : unit t
  | Match : string -> unit t
  | Apply : ('a -> 'b) t * 'a t -> 'b t
  | SkipLeft : 'a t * 'b t -> 'b t
  | SkipRight : 'a t * 'b t -> 'a t
  | Int : int t
  | Str : string t

let return x = Return x
let apply f t = Apply (f, t)
let s x = Match x
let int = Int
let str = Str
let empty = Empty

let rec first : type a. a t -> string =
 fun t ->
  match t with
  | Return _ -> ""
  | Empty -> ""
  | Match w -> w
  | Int -> ""
  | Str -> ""
  | Apply (f, t) ->
    let a = first f in
    if a <> "" then a else first t
  | SkipLeft (a, _) -> first a
  | SkipRight (a, _) -> first a
;;

let rec parse : type a. a t -> string list -> (a * string list) option =
 fun t params ->
  match t with
  | Return x -> Some (x, params)
  | Empty ->
    (match params with
    | [] -> Some ((), params)
    | _ -> None)
  | Match s ->
    (match params with
    | [] -> None
    | p :: ps when p = s -> Some ((), ps)
    | _ -> None)
  | Int ->
    (match params with
    | [] -> None
    | p :: ps ->
      (match int_of_string_opt p with
      | None -> None
      | Some r -> Some (r, ps)))
  | Str ->
    (match params with
    | [] -> None
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

module Infix = struct
  let ( <*> ) = apply
  let ( </> ) = apply
  let ( <$> ) f p = Apply (Return f, p)
  let ( *> ) x y = SkipLeft (x, y)
  let ( <* ) x y = SkipRight (x, y)
  let ( <$ ) f t = SkipRight (Return f, t)
end
