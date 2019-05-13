(**
   // Copyright 2013 Julien Schmidt. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found
// in the httprouter.LICENSE file.
*)

open Routes
open Infix

let routes =
  let classes = s "1" *> s "classes" *> str in
  let object_routes =
    [ `POST, (fun _ -> "post class") <$> classes
    ; `GET, (fun _ _ -> "get obj") <$> classes </> int
    ; `PUT, (fun _ _ -> "get obj") <$> classes </> int
    ; `GET, (fun _ -> "get class") <$> classes
    ]
  in
  let user_path = s "1" *> s "users" in
  let user_routes =
    [ `POST, "post users" <$ user_path
    ; `GET, "login" <$ s "1" *> s "login"
    ; `GET, (fun _ -> "user obj") <$> user_path *> str
    ; `PUT, (fun _ -> "user obj") <$> user_path *> str
    ; `GET, "get users" <$ user_path
    ; `DELETE, (fun _ -> "delete user") <$> user_path *> str
    ; `POST, "password reset" <$ s "1" *> s "requestPasswordReset"
    ]
  in
  let role_path = s "1" *> s "roles" in
  let role_routes =
    [ `POST, "role" <$ role_path
    ; `GET, (fun _ -> "role") <$> role_path *> int
    ; `PUT, (fun _ -> "role") <$> role_path *> int
    ; `GET, "role" <$ role_path
    ; `DELETE, (fun _ -> "role") <$> role_path *> int
    ]
  in
  let misc =
    [ `POST, (fun _ -> "file") <$> s "1" *> s "files" *> str
    ; `POST, (fun _ -> "event") <$> s "1" *> s "events" *> str
    ; `POST, "push" <$ s "1" *> s "push"
    ; `POST, "cloud" <$ s "1" *> s "functions"
    ]
  in
  let inst_param = s "1" *> s "installations" in
  let inst_routes =
    [ `POST, "install" <$ inst_param
    ; `GET, (fun _ -> "") <$> inst_param *> str
    ; `PUT, (fun _ -> "") <$> inst_param *> str
    ; `GET, "install" <$ inst_param
    ; `DELETE, (fun _ -> "") <$> inst_param *> str
    ]
  in
  with_method
    (List.concat [ object_routes; user_routes; role_routes; misc; inst_routes ])
;;

open Core_bench

let bench_static =
  Bench.Test.create ~name:"Parse Static" (fun () ->
      ignore (match_with_method ~meth:`GET ~target:"/1/users" routes))
;;

let bench_one_param =
  Bench.Test.create ~name:"Parse 1 param" (fun () ->
      ignore (match_with_method ~meth:`GET ~target:"/1/classes/ocaml" routes))
;;

let bench_two_param =
  Bench.Test.create ~name:"Parse 2 param" (fun () ->
      ignore (match_with_method ~meth:`PUT ~target:"/1/classes/ocaml/121" routes))
;;

let parse_benches = [ bench_static; bench_one_param; bench_two_param ]
