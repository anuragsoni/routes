open Routes

let routes =
  let classes = s "1" / s "classes" / str in
  let classes' = s "1" / s "classes" / str / int in
  let object_routes =
    [ (Some `POST, (classes /? nil) @--> fun _ -> "post class")
    ; (Some `GET, (classes' /? nil) @--> fun _ _ -> "")
    ; (Some `PUT, (classes' /? nil) @--> fun _ _ -> "")
    ; (Some `GET, (classes /? nil) @--> fun _ -> "")
    ]
  in
  let user_routes =
    [ Some `POST, (s "1" / s "users" /? nil) @--> "Hello"
    ; Some `GET, (s "1" / s "login" /? nil) @--> "login"
    ; (Some `GET, (s "1" / s "users" / str /? nil) @--> fun _ -> "user")
    ; (Some `PUT, (s "1" / s "users" / str /? nil) @--> fun _ -> "put user")
    ; Some `GET, (s "1" / s "users" /? nil) @--> "get user"
    ; (Some `DELETE, (s "1" / s "users" / str /? nil) @--> fun _ -> "delete user")
    ; Some `POST, (s "requestPasswordReset" /? nil) @--> "password reset"
    ]
  in
  let role_routes =
    [ Some `POST, (s "1" / s "roles" /? nil) @--> "role"
    ; (Some `GET, (s "1" / s "roles" / int /? nil) @--> fun _ -> "role")
    ; (Some `PUT, (s "1" / s "roles" / int /? nil) @--> fun _ -> "role")
    ; Some `GET, (s "1" / s "roles" /? nil) @--> "role"
    ; (Some `DELETE, (s "1" / s "roles" / int /? nil) @--> fun _ -> "role")
    ]
  in
  let misc =
    [ (Some `POST, (s "1" / s "files" / str /? nil) @--> fun _ -> "file")
    ; (Some `POST, (s "1" / s "events" / str /? nil) @--> fun _ -> "event")
    ; Some `POST, (s "1" / s "push" /? nil) @--> "role"
    ; Some `POST, (s "1" / s "functions" /? nil) @--> "cloud"
    ]
  in
  let inst_routes =
    [ Some `POST, (s "1" / s "installations" /? nil) @--> "install"
    ; (Some `GET, (s "1" / s "installations" / str /? nil) @--> fun _ -> "")
    ; (Some `PUT, (s "1" / s "installations" / str /? nil) @--> fun _ -> "")
    ; Some `GET, (s "1" / s "installations" /? nil) @--> "install"
    ; (Some `DELETE, (s "1" / s "installations" / str /? nil) @--> fun _ -> "")
    ]
  in
  one_of (List.concat [ object_routes; user_routes; role_routes; misc; inst_routes ])

let bench_static =
  let open Core in
  let open Core_bench in
  Bench.Test.create ~name:"Parse static" (fun () ->
      match' ~meth:`GET ~target:"/1/users" routes)

let benches = [ bench_static ]
