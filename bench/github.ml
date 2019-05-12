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
  let user = s "user" in
  let users = s "users" in
  let emails = user *> s "emails" in
  let users_routes =
    [ `GET, (fun _ -> "user") <$> users *> str
    ; `GET, "user" <$ user
    ; `GET, "users" <$ users
    ; `GET, "emails" <$ emails
    ; `POST, "emails" <$ emails
    ; `DELETE, "emails" <$ emails
    ; `GET, "repos" <$ user *> s "repos"
    ]
  in
  let events = s "events" in
  let user_events = users *> str <* events in
  let notifications = s "notifications" in
  let notification_thread = notifications *> s "threads" *> int in
  let activity =
    [ `GET, "events" <$ events
    ; `GET, (fun _ _ -> "repos") <$> s "repos" *> str </> str <* events
    ; `GET, (fun _ -> "org") <$> s "orgs" *> str <* events
    ; `GET, (fun _ -> "user") <$> users *> str <* s "received_events"
    ; `GET, (fun _ -> "user") <$> users *> str <* s "received_events" <* s "public"
    ; `GET, (fun _ -> "event") <$> user_events
    ; `GET, (fun _ -> "public") <$> user_events <* s "public"
    ; `GET, (fun _ _ -> "org event") <$> user_events </> s "orgs" *> str
    ; `GET, "feeds" <$ s "feeds"
    ; `GET, "notifications" <$ notifications
    ; `GET, (fun _ _ -> "repo notif") <$> s "repos" *> str </> str <* notifications
    ; `PUT, "notif" <$ notifications
    ; `PUT, (fun _ _ -> "repo notif") <$> s "repos" *> str </> str <* notifications
    ; `GET, (fun _ -> "thread id") <$> notification_thread
    ; `GET, (fun _ -> "put thread") <$> notification_thread <* s "subscription"
    ; `PUT, (fun _ -> "put thread") <$> notification_thread <* s "subscription"
    ; `DELETE, (fun _ -> "put thread") <$> notification_thread <* s "subscription"
    ; `GET, (fun _ _ -> "stars") <$> s "repos" *> str </> str <* s "stargazers"
    ; `GET, (fun _ -> "starred") <$> users *> str <* s "starred"
    ; `GET, "starred" <$ user *> s "starred"
    ; `GET, (fun _ _ -> "owner") <$> user *> s "starred" *> str </> str
    ; `PUT, (fun _ _ -> "owner") <$> user *> s "starred" *> str </> str
    ; `DELETE, (fun _ _ -> "owner") <$> user *> s "starred" *> str </> str
    ]
  in
  with_method @@ List.concat [ auth; applications; users_routes; activity ]
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
