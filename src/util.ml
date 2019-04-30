let split_path target =
  match target with
  | "" | "/" -> []
  | _ ->
    let target =
      match String.index_from_opt target 0 '?' with
      | None -> target
      | Some i -> if i = 0 then "" else String.sub target 0 i
    in
    (match String.split_on_char '/' target with
    | "" :: xs -> xs
    | xs -> xs)
;;
