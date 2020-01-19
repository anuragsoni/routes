module Method = struct
  module T = struct
    type standard =
      [ `GET
      | `HEAD
      | `POST
      | `PUT
      | `DELETE
      | `CONNECT
      | `OPTIONS
      | `TRACE
      ]

    type t =
      [ standard
      | `Other of string
      ]

    let default = `GET

    let to_string = function
      | `GET -> "GET"
      | `HEAD -> "HEAD"
      | `POST -> "POST"
      | `PUT -> "PUT"
      | `DELETE -> "DELETE"
      | `CONNECT -> "CONNECT"
      | `OPTIONS -> "OPTION"
      | `TRACE -> "TRACE"
      | `Other s -> s

    let compare m1 m2 = String.compare (to_string m1) (to_string m2)
    let pp fmt m = Format.fprintf fmt "%s" (to_string m)
    let equal m1 m2 = compare m1 m2 = 0
  end

  include T
  module M = Map.Make (T)
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
    let rec aux t params captures =
      match t, params with
      | { parsers = []; _ }, [] -> [], []
      | { parsers = rs; _ }, [] -> rs, List.rev captures
      | { children; capture; _ }, x :: xs ->
        (match KeyMap.find_opt x children with
        | None ->
          (match capture with
          | None -> [], []
          | Some t' -> aux t' xs (x :: captures))
        | Some m' -> aux m' xs captures)
    in
    aux t params []

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
  }

let conv to_ from_ = { to_; from_ }

type ('a, 'b) path =
  | End : ('a, 'a) path
  | Match : string * ('a, 'b) path -> ('a, 'b) path
  | Conv : 'c conv * ('a, 'b) path -> ('c -> 'a, 'b) path

and ('a, 'b) req = Req : Method.t * ('a, 'b) path -> ('a, 'b) req

type 'b route = Route : ('a, 'b) req * 'a -> 'b route

let route r handler = Route (r, handler)
let ( @--> ) = route
let s w r = Match (w, r)
let of_conv conv r = Conv (conv, r)
let int r = of_conv (conv string_of_int int_of_string_opt) r
let str r = of_conv (conv Fun.id (fun (x : string) -> Some x)) r
let bool r = of_conv (conv string_of_bool bool_of_string_opt) r
let ( / ) m1 m2 r = m1 @@ m2 r
let nil = End

let rec print_params : type a b. (string -> b) -> (a, b) path -> a =
 fun k -> function
  | End -> k ""
  | Match (w, fmt) -> print_params (fun s -> k @@ String.concat "/" [ w; s ]) fmt
  | Conv ({ to_; _ }, fmt) ->
    let f x = print_params (fun str -> k @@ String.concat "/" [ to_ x; str ]) fmt in
    f

let rec print_pattern : type a b. (a, b) path -> string = function
  | End -> ""
  | Match (w, fmt) -> w ^ "/" ^ print_pattern fmt
  | Conv (_, fmt) -> ":capture/" ^ print_pattern fmt

let sprintf r = print_params Fun.id r
let pp fmt r = Format.fprintf fmt "%s" (print_pattern r)

let parse_route fmt handler params =
  let rec match_target : type a b. (a, b) path -> a -> string list -> b option =
   fun t f s ->
    match t with
    | End -> Some f
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

let meth' meth r = Req (meth, r End)

let match' routes target =
  let target = String.split_on_char '/' target in
  let rec route' = function
    | [] -> None
    | Route (Req (_, r), h) :: ps ->
      (match parse_route r h target with
      | None -> route' ps
      | Some f -> Some f)
  in
  route' routes
