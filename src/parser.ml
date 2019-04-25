type 'a t = string list -> ('a * string list) option

let return x s = Some (x, s)
let fail _ = None

let take_token s =
  match s with
  | [] -> None
  | p :: ps -> Some (p, ps)
;;

let empty s =
  match s with
  | [] -> Some ((), [])
  | _ -> None
;;

let run p s = p s

let append p
           q
           s =
  match run p s with
  | None -> run q s
  | res -> res
;;

let choose xs =
  let e _ = None in
  List.fold_left (fun acc v -> append acc v) e xs
;;

let fmap p ~f s =
  match run p s with
  | None -> None
  | Some (v, rest) -> Some (f v, rest)
;;

let bind p ~f s =
  match run p s with
  | None -> None
  | Some (v, rest) ->
    let p' = f v in
    run p' rest
;;

let apply f p s =
  match run f s with
  | None -> None
  | Some (f, rest) ->
    (match p rest with
    | None -> None
    | Some (v, rest) -> Some (f v, rest))
;;

module Infix = struct
  let ( >>= ) p f = bind p ~f
  let ( >>| ) p f = fmap p ~f
  let ( <$> ) f = fmap ~f
  let ( <*> ) = apply
  let ( *> ) x y = (fun _ y -> y) <$> x <*> y
  let ( <* ) x y = (fun x _ -> x) <$> x <*> y
  let ( <+> ) x y = append x y
  let ( <|> ) p q = choose [ p; q ]
end

open Infix

let apply p1 p2 = p1 >>= fun f -> p2 >>| f

let int =
  take_token
  >>= fun t ->
  match int_of_string_opt t with
  | None -> fail
  | Some y -> return y
;;

let int32 =
  take_token
  >>= fun t ->
  match Int32.of_string_opt t with
  | None -> fail
  | Some y -> return y
;;

let int64 =
  take_token
  >>= fun t ->
  match Int64.of_string_opt t with
  | None -> fail
  | Some y -> return y
;;

let bool =
  take_token
  >>= fun t ->
  let t' = String.lowercase_ascii t in
  match t' with
  | "true" -> return true
  | "false" -> return false
  | _ -> fail
;;

let str = take_token
let string word = take_token >>= fun t -> if t = word then return word else fail
let s word = string word >>| fun _ -> ()
