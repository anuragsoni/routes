(**
   // Copyright 2013 Julien Schmidt. All rights reserved.
   // Use of this source code is governed by a BSD-style license that can be found
   // in the httprouter.LICENSE file.
*)

open Routes

let routes =
  let classes () = s "1" / s "classes" / str in
  let object_routes =
    [ (Some `POST, (classes () /? nil) @--> fun _ -> "post class")
    ; (Some `GET, (classes () / int /? nil) @--> fun _ _ -> "")
    ; (Some `PUT, (classes () / int /? nil) @--> fun _ _ -> "")
    ; (Some `GET, (classes () /? nil) @--> fun _ -> "")
    ]
  in
  let user_routes =
    let users () = s "1" / s "users" in
    let login () = s "1" / s "login" in
    [ Some `POST, (users () /? nil) @--> "Hello"
    ; Some `GET, (login () /? nil) @--> "login"
    ; (Some `GET, (users () / str /? nil) @--> fun _ -> "user")
    ; (Some `PUT, (users () / str /? nil) @--> fun _ -> "put user")
    ; Some `GET, (users () /? nil) @--> "get user"
    ; (Some `DELETE, (users () / str /? nil) @--> fun _ -> "delete user")
    ; Some `POST, (s "requestPasswordReset" /? nil) @--> "password reset"
    ]
  in
  let role_routes =
    let roles () = s "1" / s "roles" in
    [ Some `POST, (roles () /? nil) @--> "role"
    ; (Some `GET, (roles () / int /? nil) @--> fun _ -> "role")
    ; (Some `PUT, (roles () / int /? nil) @--> fun _ -> "role")
    ; Some `GET, (roles () /? nil) @--> "role"
    ; (Some `DELETE, (roles () / int /? nil) @--> fun _ -> "role")
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

open Core_bench

let bench_static =
  Bench.Test.create ~name:"Parse static" (fun () ->
      match' ~meth:`GET ~target:"/1/users" routes)

let bench_one_param =
  Bench.Test.create ~name:"Parse 1 param" (fun () ->
      match' ~meth:`GET ~target:"/1/classes/ocaml" routes)

let bench_two_param =
  Bench.Test.create ~name:"Parse 2 param" (fun () ->
      match' ~meth:`GET ~target:"/1/classes/ocaml/121" routes)

let benches = [ bench_static; bench_one_param; bench_two_param ]
