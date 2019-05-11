open Opium.Std

type person =
  { name : string
  ; age : int
  }

let to_meth = function
  | `GET -> `GET
  | `POST -> `POST
  | `HEAD -> `HEAD
  | `DELETE -> `DELETE
  | `PATCH -> failwith "PATCH is not supported"
  | `PUT -> `PUT
  | `OPTIONS -> `OPTIONS
  | `TRACE -> `TRACE
  | `CONNECT -> `CONNECT
  | `Other w -> failwith ( w ^ " is not supported." )
;;

let router routes =
  let open Routes in
  let filter handler req =
    let target = Request.uri req |> Uri.path in
    let meth = Request.meth req in
    match match_with_method routes ~target ~meth:(to_meth meth) with
    | None -> handler req
    | Some h -> h req
  in
  Rock.Middleware.create ~name:"Routes" ~filter
;;

let json_of_person { name; age } =
  let open Ezjsonm in
  dict [ "name", string name; "age", int age ]
;;

let hello (_ : Request.t) = `String "Hello World!" |> respond'

let print_person name age (_ : Request.t) =
  let person = { name; age } in
  `Json (person |> json_of_person) |> respond'
;;

open Routes
open Infix

let routes =
  with_method [ `GET, hello <$ empty; `GET, print_person <$> s "person" *> str </> int ]
;;

let _ = App.empty |> middleware (router routes) |> App.run_command
