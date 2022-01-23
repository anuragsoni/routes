(** // Copyright 2013 Julien Schmidt. All rights reserved. // Use of this source code is
    governed by a BSD-style license that can be found // in the httprouter.LICENSE file. *)

open Routes

let untyped_router =
  let open Untyped in
  one_of
    [ route "/1/classes/:a" "class"
    ; route "/1/classes" "class"
    ; route "/1/users" "hello"
    ; route "/1/login" "login"
    ; route "/1/users/:name" "user"
    ; route "/1/roles" "role"
    ; route "/1/roles/:id" "role"
    ; route "/1/files/:name" "file"
    ; route "/1/events/:name" "event"
    ; route "/1/push" "push"
    ; route "/1/functions" "functions"
    ; route "/1/installations" "install"
    ; route "/1/installations/:name" "install"
    ]
;;

let routes =
  let classes () = s "1" / s "classes" / str in
  let object_routes =
    [ ((classes () /? nil) @--> fun _ -> "post class")
    ; ((classes () / int /? nil) @--> fun _ _ -> "")
    ]
  in
  let user_routes =
    let users () = s "1" / s "users" in
    let login () = s "1" / s "login" in
    [ (users () /? nil) @--> "Hello"
    ; (login () /? nil) @--> "login"
    ; ((users () / str /? nil) @--> fun _ -> "user")
    ; ((users () / str /? nil) @--> fun _ -> "put user")
    ; (users () /? nil) @--> "get user"
    ; ((users () / str /? nil) @--> fun _ -> "delete user")
    ; (s "requestPasswordReset" /? nil) @--> "password reset"
    ]
  in
  let role_routes =
    let roles () = s "1" / s "roles" in
    [ (roles () /? nil) @--> "role"
    ; ((roles () / int /? nil) @--> fun _ -> "role")
    ; ((roles () / int /? nil) @--> fun _ -> "role")
    ; (roles () /? nil) @--> "role"
    ; ((roles () / int /? nil) @--> fun _ -> "role")
    ]
  in
  let misc =
    [ ((s "1" / s "files" / str /? nil) @--> fun _ -> "file")
    ; ((s "1" / s "events" / str /? nil) @--> fun _ -> "event")
    ; (s "1" / s "push" /? nil) @--> "role"
    ; (s "1" / s "functions" /? nil) @--> "cloud"
    ]
  in
  let inst_routes =
    [ (s "1" / s "installations" /? nil) @--> "install"
    ; ((s "1" / s "installations" / str /? nil) @--> fun _ -> "")
    ; ((s "1" / s "installations" / str /? nil) @--> fun _ -> "")
    ; (s "1" / s "installations" /? nil) @--> "install"
    ; ((s "1" / s "installations" / str /? nil) @--> fun _ -> "")
    ]
  in
  one_of (List.concat [ object_routes; user_routes; role_routes; misc; inst_routes ])
;;

open Core_bench

let bench_static =
  Bench.Test.create ~name:"Parse static" (fun () -> match' ~target:"/1/users" routes)
;;

let bench_static_untyped =
  Bench.Test.create ~name:"Parse static (Untyped)" (fun () ->
      Untyped.match' ~target:"/1/users" untyped_router)
;;

let bench_one_param =
  Bench.Test.create ~name:"Parse 1 param" (fun () ->
      match' ~target:"/1/classes/ocaml" routes)
;;

let bench_one_param_untyped =
  Bench.Test.create ~name:"Parse 1 param (Untyped)" (fun () ->
      Untyped.match' ~target:"/1/classes/ocaml" untyped_router)
;;

let bench_two_param =
  Bench.Test.create ~name:"Parse 2 param" (fun () ->
      match' ~target:"/1/classes/ocaml/121" routes)
;;

let bench_two_param_untyped =
  Bench.Test.create ~name:"Parse 2 param (Untyped)" (fun () ->
      Untyped.match' ~target:"/1/classes/ocaml/121" untyped_router)
;;

let benches =
  [ bench_static
  ; bench_static_untyped
  ; bench_one_param
  ; bench_one_param_untyped
  ; bench_two_param
  ; bench_two_param_untyped
  ]
;;
