type 'a conv =
  { to_ : 'a -> string
  ; from_ : string -> 'a option
  }

let conv to_ from_ = { to_; from_ }

type ('a, 'b) t =
  | End : ('a, 'a) t
  | Match : string * ('a, 'b) t -> ('a, 'b) t
  | Conv : 'c conv * ('a, 'b) t -> ('c -> 'a, 'b) t

and ('a, 'b) req = Req : string * ('a, 'b) t -> ('a, 'b) req

type 'b route = Route : ('a, 'b) req * 'a -> 'b route

let route r handler = Route (r, handler)
let ( ==> ) = route
let s w r = Match (w, r)
let of_conv conv r = Conv (conv, r)
let int r = of_conv (conv string_of_int int_of_string_opt) r
let str r = of_conv (conv Fun.id (fun (x : string) -> Some x)) r
let bool r = of_conv (conv string_of_bool bool_of_string_opt) r
let ( </> ) m1 m2 r = m1 @@ m2 r

let rec print_params : type a b. (string -> b) -> (a, b) t -> a =
 fun k -> function
  | End -> k ""
  | Match (w, fmt) -> print_params (fun s -> k @@ String.concat "/" [ w; s ]) fmt
  | Conv ({ to_; _ }, fmt) ->
    let f x = print_params (fun str -> k @@ String.concat "/" [ to_ x; str ]) fmt in
    f

let rec print_pattern : type a b. (a, b) t -> string = function
  | End -> ""
  | Match (w, fmt) -> w ^ "/" ^ print_pattern fmt
  | Conv (_, fmt) -> ":capture/" ^ print_pattern fmt

let parse_route fmt handler params =
  let rec match_target : type a b. (a, b) t -> a -> string list -> b option =
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
