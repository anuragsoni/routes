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
;;
