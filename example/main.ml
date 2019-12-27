open Base
open Httpaf
open Httpaf_lwt_unix

let get_content_length = function
  | `String s -> String.length s
  | `Bigstring b -> Bigstringaf.length b
;;

let respond_with_text reqd status text =
  let headers =
    Headers.of_list [ "content-length", Int.to_string (get_content_length text) ]
  in
  match text with
  | `String s -> Reqd.respond_with_string reqd (Response.create ~headers status) s
  | `Bigstring b -> Reqd.respond_with_bigstring reqd (Response.create ~headers status) b
;;

module Handlers = struct
  let greeter id name city (req : Httpaf.Request.t) =
    Logs.info (fun m ->
        m "Woohoo! I have access to the Httpaf request here: Id: %d %s" id req.target);
    `String ("Hello, " ^ name ^ ". How was your trip to " ^ city ^ "?")
  ;;

  let sum a b _ = `String (Printf.sprintf "The sum of %d and %d = %d" a b (a + b))
  let return_bigstring _ = `Bigstring (Bigstringaf.of_string "Hello world" ~off:0 ~len:11)

  let users name rest _ =
    `String (Printf.sprintf "User: %s Rest: %s" name rest)

  let users' name rest _ =
    `String (Printf.sprintf "User: %s Rest: %s" name rest)

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
    ; `GET, users' <$> s "users" *> str </> str
    ; `GET, users <$> s "users" *> str </> capture_all
    ]
;;

let request_handler _ reqd =
  let req = Reqd.request reqd in
  match Routes.match_with_method ~target:req.target ~meth:req.meth routes with
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

let main port =
  let open Lwt.Infix in
  let listen_address = Unix.(ADDR_INET (inet_addr_loopback, port)) in
  Lwt.async (fun () ->
      Lwt_io.establish_server_with_client_socket
        ~backlog:11_000
        listen_address
        (Server.create_connection_handler ~request_handler ~error_handler)
      >>= fun _server -> Lwt.return_unit);
  let forever, _ = Lwt.wait () in
  Lwt_main.run forever
;;

let () =
  Logs.set_level (Some Logs.Info);
  Logs.set_reporter @@ Logs_fmt.reporter ();
  let port = ref 8080 in
  Caml.Arg.parse
    [ "-p", Caml.Arg.Set_int port, " Port number (default is 8080)" ]
    ignore
    "Routing example";
  main !port
;;
