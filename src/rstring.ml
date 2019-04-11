type t =
  { str : String.t
  ; off : int
  ; len : int
  }

let of_string x = { str = x; off = 0; len = String.length x }
let get t i = t.str.[t.off + i]
let length t = t.len - t.off
let empty = { str = ""; off = 0; len = 0 }

let to_string t =
  let len = length t in
  StringLabels.sub t.str ~pos:t.off ~len
;;

let drop_i t i =
  let len = length t in
  if i > len then empty else { t with off = t.off + i }
;;

let take_i t i =
  let len = length t in
  if i > len then t else { t with len = t.off + i }
;;

let take_while_i t ~f =
  let len = length t in
  let rec loop i = if i = len then i else if f (get t i) then loop (i + 1) else i in
  loop 0
;;

let drop_while ~f t =
  let i = take_while_i t ~f:(fun x -> not (f x)) in
  drop_i t i
;;

let drop_prefix prefix t =
  let len = String.length prefix in
  if len > length t
  then None
  else (
    try
      for i = 0 to len - 1 do
        if get t i <> prefix.[i] then raise_notrace Exit
      done;
      Some (drop_i t len)
    with
    | Exit -> None)
;;

let take_while ~f t =
  let i = take_while_i ~f t in
  take_i t i, drop_i t i
;;

let take_while_opt ~f t =
  let take, rest = take_while ~f t in
  Some (to_string take, rest)
;;

let is_empty t = length t = 0
let to_int = int_of_string_opt
let to_int32 = Int32.of_string_opt
let to_int64 = Int64.of_string_opt
let to_bool = bool_of_string_opt
let tail t = drop_i t 1
