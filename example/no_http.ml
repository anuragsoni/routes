module R = struct
  open Routes

  let sum a b = Printf.sprintf "Sum of %d and %d = %d" a b (a + b)
  let id_handler id = Printf.sprintf "Requested user with id %d" id
  let admin_handler a = if a then "User is admin" else "User is not an admin"
  let user () = s "user"
  let user_and_id = user () / int /? nil
  let user_and_admin = user () / bool /? nil
  let q = s "confusing" /? nil

  let routes =
    one_of
      [ route (s "hi" /? nil) "Hello, World"
      ; route (s "hello" / s "from" / s "routes" /? nil) "Hello, Routes"
      ; route (s "sum" / int / int /? nil) sum
      ; route user_and_id id_handler
      ; route user_and_admin admin_handler
      ; route q "Foobar"
      ]
  ;;
end

let unwrap_result = function
  | Routes.NoMatch -> "No match"
  | FullMatch r -> r
  | MatchWithTrailingSlash r -> r
;;

let () =
  let targets =
    [ "sum/12/127"
    ; "/hi"
    ; "/hello/from/routes"
    ; "/user/121"
    ; "user/false"
    ; "confusing/"
    ; "confusing"
    ]
  in
  List.iter
    (fun target -> print_endline (unwrap_result @@ Routes.match' ~target R.routes))
    targets
;;
