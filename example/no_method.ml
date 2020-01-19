module R = struct
  open Routes

  let sum a b = Printf.sprintf "Sum of %d and %d = %d" a b (a + b)
  let id_handler id = Printf.sprintf "Requested user with id %d" id
  let admin_handler a = if a then "User is admin" else "User is not an admin"
  let route r = None, r

  let routes =
    one_of
      [ route @@ (s "hi" /? nil) @--> "Hello, World"
      ; route @@ (s "hello" / s "from" / s "routes" /? nil) @--> "Hello, Routes"
      ; route @@ (s "sum" / int / int /? nil) @--> sum
      ; route @@ (s "user" / int /? nil) @--> id_handler
      ]
end

let unwrap_result = function
  | None -> "No match"
  | Some r -> r

let () =
  let targets =
    [ "sum/12/127"
    ; "/hi"
    ; "/hello/from/routes"
    ; "/user/121"
    ; "user/false"
    ; "confusing/121"
    ; "confusing/foobar"
    ]
  in
  List.iter
    (fun target -> print_endline (unwrap_result @@ Routes.match' ~target R.routes))
    targets
