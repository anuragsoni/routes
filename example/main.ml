open Core
open Async
open Httpaf
open Httpaf_async

let get_content_length = function
  | `String s -> String.length s
  | `Bigstring b -> Bigstringaf.length b
;;

let respond_with_text reqd status text =
  let headers =
    Headers.of_list [ "content-length", string_of_int (get_content_length text) ]
  in
  match text with
  | `String s -> Reqd.respond_with_string reqd (Response.create ~headers status) s
  | `Bigstring b -> Reqd.respond_with_bigstring reqd (Response.create ~headers status) b
;;

module Handlers = struct
  let greeter id name city (req : Httpaf.Request.t) =
    Log.Global.printf
      "Woohoo! I have access to the Httpaf request here: Id: %d %s"
      id
      req.target;
    `String ("Hello, " ^ name ^ ". How was your trip to " ^ city ^ "?")
  ;;

  let sum a b _ = `String (Printf.sprintf "The sum of %d and %d = %d" a b (a + b))

  let return_bigstring _ =
    `Bigstring (Bigstringaf.of_string "Hello world" ~off:0 ~len:11)
  ;;

  (* let retrieve_user state name id = *)
  (*   let req : Request.t = Routes.RouterState.get_request state in *)
  (*   Log.Global.printf "Fetching user with name %s and id %ld." name id; *)
  (*   `String req.target *)
  (* ;; *)
end

let routes =
  let open Routes in
  let open Infix in
  let open Handlers in
  with_method
    [ `GET, return_bigstring <$ empty
    ; `GET, greeter <$> s "greet" *> int </> str </> str
    ; `GET, sum <$> s "sum" *> int </> int
    ]
;;

let to_meth = function
  | `GET -> `GET
  | `POST -> `POST
  | `HEAD -> `HEAD
  | `DELETE -> `DELETE
  | `PATCH -> failwith "PATCH not supported"
  | `PUT -> `PUT
  | `OPTIONS -> `OPTIONS
  | `TRACE -> `TRACE
  | `CONNECT -> `CONNECT
  | `Other w -> failwith (w ^ " is not supported")
;;

let request_handler _ reqd =
  let req = Reqd.request reqd in
  match Routes.match_with_method ~target:req.target ~meth:(to_meth req.meth) routes with
  | None ->
    respond_with_text reqd `Not_found (`String (Status.default_reason_phrase `Not_found))
  | Some response -> respond_with_text reqd `OK (response req)
;;

let error_handler _ ?request:_ error start_response =
  let response_body = start_response Headers.empty in
  (match error with
  | `Exn exn ->
    Body.write_string response_body (Exn.to_string exn);
    Body.write_string response_body "\n"
  | #Status.standard as error ->
    Body.write_string response_body (Status.default_reason_phrase error));
  Body.close_writer response_body
;;

let main port max_accepts_per_batch () =
  let where_to_listen = Tcp.Where_to_listen.of_port port in
  Tcp.(
    Server.create_sock
      ~on_handler_error:`Ignore
      ~backlog:11_000
      ~max_connections:10_000
      ~max_accepts_per_batch
      where_to_listen)
    (Server.create_connection_handler ~request_handler ~error_handler)
  >>= fun _server -> Deferred.never ()
;;

let () =
  Command.async
    ~summary:"Start a hello world Async server"
    Command.Param.(
      map
        (both
           (flag
              "-p"
              (optional_with_default 8080 int)
              ~doc:"int Source port to listen on")
           (flag "-a" (optional_with_default 1 int) ~doc:"int Maximum accepts per batch"))
        ~f:(fun (port, accepts) () -> main port accepts ()))
  |> Command.run
;;
