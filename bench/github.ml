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
    [ `GET, (fun _ _ -> "client token") <$> applications_root *> str </> s "tokens" *> str
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
    ; `GET, (fun _ _ -> "subscribe") <$> s "repos" *> str </> str <* s "subscribers"
    ; `GET, (fun _ -> "subscription") <$> users *> str <* s "subscriptions"
    ; `GET, "user subscription" <$ user *> s "subscription"
    ; ( `GET
      , (fun _ _ -> "repo subscription") <$> s "repos" *> str </> str <* s "subscription"
      )
    ; ( `POST
      , (fun _ _ -> "repo subscription") <$> s "repos" *> str </> str <* s "subscription"
      )
    ; ( `DELETE
      , (fun _ _ -> "repo subscription") <$> s "repos" *> str </> str <* s "subscription"
      )
    ; `GET, (fun _ _ -> "owner subscription") <$> user *> s "subscription" *> str </> str
    ; `PUT, (fun _ _ -> "owner subscription") <$> user *> s "subscription" *> str </> str
    ; ( `DELETE
      , (fun _ _ -> "owner subscription") <$> user *> s "subscription" *> str </> str )
    ]
  in
  let gists = s "gists" in
  let gist_routes =
    [ `GET, (fun _ -> "user gists") <$> users *> str <* gists
    ; `GET, "gists" <$ gists
    ; `GET, (fun _ -> "gist") <$> gists *> int
    ; `POST, "post gists" <$ gists
    ; `PUT, (fun _ -> "gist") <$> gists *> int <* s "star"
    ; `DELETE, (fun _ -> "gist") <$> gists *> int <* s "star"
    ; `GET, (fun _ -> "gist") <$> gists *> int <* s "star"
    ; `POST, (fun _ -> "gist") <$> gists *> int <* s "forks"
    ; `DELETE, (fun _ -> "delete") <$> gists *> int
    ]
  in
  let repo_owner = s "repos" *> str in
  let git_blob = s "git" *> s "blobs" in
  let git_data_routes =
    [ `GET, (fun _ _ _ -> "") <$> repo_owner </> str </> git_blob *> str
    ; `POST, (fun _ _ -> "") <$> repo_owner </> str <* git_blob
    ; `GET, (fun _ _ _ -> "") <$> repo_owner </> str </> s "git" *> s "commits" *> str
    ; `POST, (fun _ _ -> "") <$> repo_owner </> str <* s "git" <* s "commits"
    ; `GET, (fun _ _ -> "") <$> repo_owner </> str <* s "git" <* s "refs"
    ; `POST, (fun _ _ -> "") <$> repo_owner </> str <* s "git" <* s "refs"
    ; `GET, (fun _ _ _ -> "") <$> repo_owner </> str </> s "git" *> s "tags" *> str
    ; `POST, (fun _ _ -> "") <$> repo_owner </> str <* s "git" *> s "tags"
    ; `GET, (fun _ _ _ -> "") <$> repo_owner </> str </> s "git" *> s "trees" *> str
    ; `POST, (fun _ _ -> "") <$> repo_owner </> str <* s "git" *> s "trees"
    ]
  in
  let misc_routes =
    [ `GET, "emojis" <$ s "emojis"
    ; `GET, "ignore" <$ s "gitignore" *> s "templates"
    ; `GET, (fun n -> n) <$> s "gitignore" *> s "templates" *> str
    ; `POST, "marky" <$ s "markdown"
    ; `POST, "marky raw" <$ s "markdown" *> s "raw"
    ; `GET, "meta" <$ s "meta"
    ; `GET, "rate" <$ s "rate_limit"
    ]
  in
  let issues = s "issues" in
  let issue_routes =
    [ `GET, "issue" <$ issues
    ; `GET, "user issue" <$ user *> issues
    ; `GET, (fun o -> o) <$> s "orgs" *> str <* issues
    ; `GET, (fun _ _ -> "repo issue") <$> repo_owner </> str <* issues
    ; `GET, (fun _ _ _ -> "repo issue") <$> repo_owner </> str </> issues *> int
    ; `POST, (fun _ _ -> "repo issue") <$> repo_owner </> str <* issues
    ; `GET, (fun _ _ -> "assigned") <$> repo_owner </> str <* s "assignees"
    ; `GET, (fun _ _ _ -> "assigned") <$> repo_owner </> str </> s "assignees" *> str
    ; ( `GET
      , (fun _ _ _ -> "comments") <$> repo_owner </> str </> issues *> int <* s "comments"
      )
    ; ( `POST
      , (fun _ _ _ -> "comments") <$> repo_owner </> str </> issues *> int <* s "comments"
      )
    ; ( `GET
      , (fun _ _ _ -> "comments") <$> repo_owner </> str </> issues *> int <* s "events" )
    ]
  in
  with_method
  @@ List.concat
       [ auth
       ; applications
       ; users_routes
       ; activity
       ; gist_routes
       ; git_data_routes
       ; misc_routes
       ; issue_routes
       ]
;;

open Core_bench

let bench_static =
  Bench.Test.create ~name:"Github Static" (fun () ->
      match_with_method ~meth:`GET ~target:"/user/repos" router)
;;

let bench_github_param =
  Bench.Test.create ~name:"Github Params" (fun () ->
      match_with_method ~meth:`GET ~target:"/repos/anuragsoni/routes/stargazers" router)
;;

let github_benches = [ bench_static; bench_github_param ]
