(**
   // Copyright 2013 Julien Schmidt. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found
// in the httprouter.LICENSE file.
*)

let urls =
  [ `GET, "/authorizations"; `GET, "/authorizations/12"; `POST, "/authorizations" ]
;;

open Routes
open Infix

let router =
  let auth_root = s "authorizations" in
  let auth_id = s "authorizations" *> int in
  let applications_root = s "applications" in
  let auth =
    [ `GET, "root" <$ auth_root
    ; `GET, (fun _ -> "Auth with id") <$> auth_id
    ; `POST, "postroot" <$ auth_root
    ; `DELETE, (fun _ -> "Delete with id") <$> auth_id
    ]
  in
  let applications =
    [ ( `GET
      , (fun _ _ -> "client token") <$> applications_root *> str </> s "tokens" *> str )
    ; `DELETE, (fun _ -> "delete token") <$> applications_root *> str <* s "tokens"
    ; `DELETE, (fun _ _ -> "delete") <$> applications_root *> str </> s "tokens" *> str
    ]
  in
  let users =
    let user = s "user" in
    let users = s "users" in
    let emails = user *> s "emails" in
    [ `GET, (fun _ -> "user") <$> users *> str
    ; `GET, "user" <$ user
    ; `GET, "users" <$ users
    ; `GET, "emails" <$ emails
    ; `POST, "emails" <$ emails
    ; `DELETE, "emails" <$ emails
    ; `GET, "repos" <$ user *> s "repos"
    ]
  in
  let activity =
    [ `GET, (fun _ _ -> "stars") <$> s "repos" *> str </> str <* s "stargazers" ]
  in
  with_method @@ List.concat [ auth; applications; users; activity ]
;;

open Core_bench

let bench_static =
  Bench.Test.create ~name:"Github Static" (fun () ->
      ignore (match_with_method ~meth:`GET ~target:"/user/repos" router))
;;

let bench_github_param =
  Bench.Test.create ~name:"Github Params" (fun () ->
      ignore
        (match_with_method
           ~meth:`GET
           ~target:"/repos/anuragsoni/routes/stargazers"
           router))
;;

let github_benches = [ bench_static; bench_github_param ]
