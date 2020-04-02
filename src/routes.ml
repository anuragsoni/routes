module Util = struct
  let split_path target =
    let split_target target =
      match target with
      | "" | "/" -> []
      | _ ->
        (match String.split_on_char '/' target with
        | "" :: xs -> xs
        | xs -> xs)
    in
    match String.index_opt target '?' with
    | None -> split_target target
    | Some 0 -> []
    | Some i -> split_target (String.sub target 0 i)
end

module PatternTrie = struct
  module Key = struct
    type t =
      | Match : string -> t
      | Capture : t
  end

  module KeyMap = Map.Make (String)

  type 'a node =
    { parsers : 'a list
    ; children : 'a node KeyMap.t
    ; capture : 'a node option
    }

  type 'a t = 'a node

  let empty = { parsers = []; children = KeyMap.empty; capture = None }

  let feed_params t params =
    let rec aux t params =
      match t, params with
      | { parsers = []; _ }, [] -> []
      | { parsers = rs; _ }, [] -> rs
      | { parsers = rs; _ }, [ "" ] -> rs
      | { children; capture; _ }, x :: xs ->
        (match KeyMap.find_opt x children with
        | None ->
          (match capture with
          | None -> []
          | Some t' -> aux t' xs)
        | Some m' -> aux m' xs)
    in
    aux t params

  let add k v t =
    let rec aux k t =
      match k, t with
      | [], ({ parsers = x; _ } as n) -> { n with parsers = v :: x }
      | x :: r, ({ children; capture; _ } as n) ->
        (match x with
        | Key.Match w ->
          let t' =
            match KeyMap.find_opt w children with
            | None -> empty
            | Some v -> v
          in
          let t'' = aux r t' in
          { n with children = KeyMap.add w t'' children }
        | Key.Capture ->
          let t' =
            match capture with
            | None -> empty
            | Some v -> v
          in
          let t'' = aux r t' in
          { n with capture = Some t'' })
    in
    aux k t
end

type 'a conv =
  { to_ : 'a -> string
  ; from_ : string -> 'a option
  ; label : string
  }

let conv to_ from_ label = { to_; from_; label }

type ('a, 'b) path =
  | End : { trailing_slash : bool } -> ('a, 'a) path
  | Match : string * ('a, 'b) path -> ('a, 'b) path
  | Conv : 'c conv * ('a, 'b) path -> ('c -> 'a, 'b) path

type 'b route = Route : ('a, 'b) path * 'a -> 'b route
type 'b router = 'b route PatternTrie.t

let pattern to_ from_ label r = Conv (conv to_ from_ label, r)
let empty_router = PatternTrie.empty
let ( @--> ) r handler = Route (r, handler)
let s w r = Match (w, r)
let of_conv conv r = Conv (conv, r)
let int r = of_conv (conv string_of_int int_of_string_opt ":int") r
let int64 r = of_conv (conv Int64.to_string Int64.of_string_opt ":int64") r
let int32 r = of_conv (conv Int32.to_string Int32.of_string_opt ":int32") r
let str r = of_conv (conv (fun x -> x) (fun x -> Some x) ":string") r
let bool r = of_conv (conv string_of_bool bool_of_string_opt ":bool") r
let ( / ) m1 m2 r = m1 @@ m2 r
let ( /? ) m1 m2 = m1 m2
let nil = End { trailing_slash = false }
let trail = End { trailing_slash = true }

let rec route_pattern : type a b. (a, b) path -> PatternTrie.Key.t list = function
  | End _ -> []
  | Match (w, fmt) -> PatternTrie.Key.Match w :: route_pattern fmt
  | Conv (_, fmt) -> PatternTrie.Key.Capture :: route_pattern fmt

let rec pp_path' : type a b. (a, b) path -> string list = function
  | End { trailing_slash } -> if trailing_slash then [ "" ] else []
  | Match (w, fmt) -> w :: pp_path' fmt
  | Conv ({ label; _ }, fmt) -> label :: pp_path' fmt

let pp_path fmt r = Format.fprintf fmt "%s" ("/" ^ String.concat "/" @@ pp_path' r)
let pp_route fmt (Route (p, _)) = pp_path fmt p

let rec ksprintf' : type a b. (string list -> b) -> (a, b) path -> a =
 fun k -> function
  | End { trailing_slash } -> if trailing_slash then k [ "" ] else k []
  | Match (w, fmt) -> ksprintf' (fun s -> k @@ (w :: s)) fmt
  | Conv ({ to_; _ }, fmt) -> fun x -> ksprintf' (fun rest -> k @@ (to_ x :: rest)) fmt

let sprintf r = ksprintf' (fun x -> "/" ^ String.concat "/" x) r

let parse_route fmt handler params =
  let rec match_target : type a b. (a, b) path -> a -> string list -> b option =
   fun t f s ->
    match t with
    | End { trailing_slash } ->
      (match s with
      | [ "" ] when trailing_slash = true -> Some f
      | [] when trailing_slash = false -> Some f
      | _ -> None)
    | Match (x, fmt) ->
      (match s with
      | x' :: xs when x = x' -> match_target fmt f xs
      | _ -> None)
    | Conv ({ from_; _ }, fmt) ->
      (match s with
      | [] -> None
      | x :: xs ->
        (match from_ x with
        | None -> None
        | Some x' -> match_target fmt (f x') xs))
  in
  match_target fmt handler params

let one_of routes =
  let routes = List.rev routes in
  List.fold_left
    (fun routes (Route (r, _) as route) ->
      let patterns = route_pattern r in
      PatternTrie.add patterns route routes)
    empty_router
    routes

let add_route route routes =
  let (Route (r, _)) = route in
  let patterns = route_pattern r in
  PatternTrie.add patterns route routes

let run_routes target router =
  let routes = PatternTrie.feed_params router target in
  let rec aux = function
    | [] -> None
    | Route (r, h) :: rs ->
      (match parse_route r h target with
      | None -> aux rs
      | Some r -> Some r)
  in
  aux routes

let match' routes ~target =
  let target = Util.split_path target in
  let matcher = run_routes target in
  matcher routes
