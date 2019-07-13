let split_path ignore_trailing_slash target =
  let split_target target =
    match target with
    | "" -> []
    | _ ->
      let strip_trailing_slash target =
        match String.length target with
        | 0 -> target
        | len -> if target.[len - 1] = '/' then String.sub target 0 (len - 1) else target
      in
      let target =
        if ignore_trailing_slash then strip_trailing_slash target else target
      in
      (match String.split_on_char '/' target with
      | "" :: xs -> xs
      | xs -> xs)
  in
  match String.index_opt target '?' with
  | None -> split_target target
  | Some 0 -> []
  | Some i -> split_target (String.sub target 0 i)
;;
