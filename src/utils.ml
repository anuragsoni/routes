module Opt = struct
  let bind t f =
    match t with
    | None -> None
    | Some v -> f v
  ;;

  let map t f =
    match t with
    | None -> None
    | Some v -> Some (f v)
  ;;

  module Infix = struct
    let ( >>= ) = bind
    let ( >>| ) = map
  end
end
