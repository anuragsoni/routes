type t =
  { prefix : string list
  ; matched : string list
  }

let create ~prefix ~matched = { prefix; matched }
let matched t = t.matched
let of_parts' xs = { prefix = []; matched = xs }
let of_parts x = of_parts' @@ Util.split_path x
let wildcard_match t = String.concat "/" ("" :: t.matched)
let prefix t = String.concat "/" ("" :: t.prefix)
