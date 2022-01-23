module PatternTrie = Trie
module Parts = Parts
module Untyped = Untyped

type 'a conv =
  { to_ : 'a -> string
  ; from_ : string -> 'a option
  ; label : string
  }

let conv to_ from_ label = { to_; from_; label }

type ('a, 'b) path =
  | End : ('a, 'a) path
  | Wildcard : (Parts.t -> 'a, 'a) path
  | Match : string * ('a, 'b) path -> ('a, 'b) path
  | Conv : 'c conv * ('a, 'b) path -> ('c -> 'a, 'b) path

type 'b route = Route : ('a, 'c) path * 'a * ('c -> 'b) -> 'b route
type 'b router = 'b route PatternTrie.t

let pattern to_ from_ label r = Conv (conv to_ from_ label, r)
let custom ~serialize:to_ ~parse:from_ ~label r = Conv (conv to_ from_ label, r)
let empty_router = PatternTrie.empty
let ( @--> ) r handler = Route (r, handler, fun x -> x)
let route r handler = Route (r, handler, fun x -> x)
let s w r = Match (w, r)
let of_conv conv r = Conv (conv, r)
let int r = of_conv (conv string_of_int int_of_string_opt ":int") r
let int64 r = of_conv (conv Int64.to_string Int64.of_string_opt ":int64") r
let int32 r = of_conv (conv Int32.to_string Int32.of_string_opt ":int32") r
let str r = of_conv (conv (fun x -> x) (fun x -> Some x) ":string") r
let bool r = of_conv (conv string_of_bool bool_of_string_opt ":bool") r
let wildcard = Wildcard
let ( / ) m1 m2 r = m1 @@ m2 r
let nil = End
let ( /? ) m1 m2 = m1 m2

let rec route_pattern : type a b. (a, b) path -> PatternTrie.Key.t list = function
  | End -> []
  | Wildcard -> [ PatternTrie.Key.Wildcard ]
  | Match (w, fmt) -> PatternTrie.Key.Match w :: route_pattern fmt
  | Conv (_, fmt) -> PatternTrie.Key.Capture :: route_pattern fmt
;;

let pp_path' path =
  let rec aux : type a b. (a, b) path -> string list = function
    | End -> []
    | Wildcard -> [ ":wildcard" ]
    | Match (w, fmt) -> w :: aux fmt
    | Conv ({ label; _ }, fmt) -> label :: aux fmt
  in
  aux path
;;

let pp_target fmt t = Format.fprintf fmt "%s" ("/" ^ String.concat "/" @@ pp_path' t)
let string_of_path t = Format.asprintf "%a" pp_target t
let pp_route fmt (Route (p, _, _)) = pp_target fmt p
let string_of_route r = Format.asprintf "%a" pp_route r

let ksprintf' k path =
  let rec aux : type a b. (string list -> b) -> (a, b) path -> a =
   fun k -> function
    | End -> k []
    | Wildcard -> fun parts -> k (List.concat [ Parts.matched parts; [] ])
    | Match (w, fmt) -> aux (fun s -> k @@ (w :: s)) fmt
    | Conv ({ to_; _ }, fmt) -> fun x -> aux (fun rest -> k @@ (to_ x :: rest)) fmt
  in
  aux k path
;;

let ksprintf k t = ksprintf' (fun x -> k ("/" ^ String.concat "/" x)) t
let sprintf t = ksprintf (fun x -> x) t

type 'a match_result =
  | FullMatch of 'a
  | MatchWithTrailingSlash of 'a
  | NoMatch

let parse_route path handler params =
  let rec match_target
      : type a b. (a, b) path -> a -> string list -> string list -> b match_result
    =
   fun t f seen s ->
    match t with
    | End ->
      (match s with
      | [ "" ] -> MatchWithTrailingSlash f
      | [] -> FullMatch f
      | _ -> NoMatch)
    | Wildcard -> FullMatch (f (Parts.create ~prefix:(List.rev seen) ~matched:s))
    | Match (x, fmt) ->
      (match s with
      | x' :: xs when x = x' -> match_target fmt f (x' :: seen) xs
      | _ -> NoMatch)
    | Conv ({ from_; _ }, fmt) ->
      (match s with
      | [] -> NoMatch
      | x :: xs ->
        (match from_ x with
        | None -> NoMatch
        | Some x' -> match_target fmt (f x') (x :: seen) xs))
  in
  match_target path handler [] params
;;

let one_of routes =
  let routes = List.rev routes in
  List.fold_left
    (fun routes (Route (path, _, _) as route) ->
      let patterns = route_pattern path in
      PatternTrie.add ~raise_on_ambiguous:false patterns route routes)
    empty_router
    routes
;;

let union = PatternTrie.union

let add_route route routes =
  let (Route (path, _, _)) = route in
  let patterns = route_pattern path in
  PatternTrie.add ~raise_on_ambiguous:false patterns route routes
;;

let map f (Route (r, h, g)) = Route (r, h, fun x -> f (g x))

let rec match_routes target = function
  | [] -> NoMatch
  | Route (r, h, f) :: rs ->
    (match parse_route r h target with
    | NoMatch -> match_routes target rs
    | FullMatch r -> FullMatch (f r)
    | MatchWithTrailingSlash r -> MatchWithTrailingSlash (f r))
;;

let match' router ~target =
  let target = Util.split_path target in
  let routes, _captures = PatternTrie.feed_params router target in
  match_routes target routes
;;

let ( /~ ) m path = m path
