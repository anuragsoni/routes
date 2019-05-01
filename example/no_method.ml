open Routes
open Infix

(** Handlers can be defined outside the [choice] method. *)
let sum a b = Printf.sprintf "Sum of %d and %d = %d" a b (a + b)

(** We can build up our route matchers piece by piece. *)
let user = s "user"

let user_and_id = user *> int64
let user_and_admin = user *> bool
let id_handler id = Printf.sprintf "Requested user with id %Ld" id
let admin_handler a = if a then "User is admin" else "User is not an admin"

(** Routes defined earlier have higher precedence *)
let q = "Foobar" <$ s "confusing" <* str

(** r has an overlap with q since both match the same number of segments.
    and q is more general. As a result anything that matches r, also matches
    q and thus r is never matched. In future i'd like to perform checks
    and warn the user about ambiguous route matches and crash early. *)
let r = (fun _ -> "Bad") <$ s "confusing" </> int

let routes =
  choice
    [ "Hello, World!" <$ s "hi"
    ; "Hello, Routes" <$ s "hello" <* s "from" <* s "routes"
    ; sum <$> s "sum" *> int </> int
    ; id_handler <$> user_and_id
    ; admin_handler <$> user_and_admin
    ; q
    ; r
    ]
;;

let unwrap_result = function
  | None -> "No match"
  | Some r -> r
;;

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
  List.iter (fun t -> print_endline (unwrap_result (match' routes t))) targets
;;
