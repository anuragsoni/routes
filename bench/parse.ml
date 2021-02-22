(** // Copyright 2013 Julien Schmidt. All rights reserved. // Use of this source code is
    governed by a BSD-style license that can be found // in the httprouter.LICENSE file. *)

open Bechamel
open Routes

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

let test_routes path = Staged.stage @@ fun () -> ignore (match' ~target:path routes)

let bench =
  Test.make_grouped
    ~name:"Parse.com"
    Test.
      [ make ~name:"Parse static" @@ test_routes "/1/users"
      ; make ~name:"Parse 1 param" @@ test_routes "/1/classes/ocaml"
      ; make ~name:"Parse 2 params" @@ test_routes "/1/classes/ocaml/121"
      ]
;;
