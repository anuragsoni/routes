open Httpaf
open Httpaf_lwt_unix

let respond_with_text reqd status text =
  let headers =
    Headers.of_list [ "content-length", Int.to_string (String.length text) ]
  in
  Reqd.respond_with_string reqd (Response.create ~headers status) text

module Handlers = struct
  let greeter id name city { Request.target; _ } =
    Logs.info (fun m ->
        m "Woohoo! I have access to the Httpaf request here: Id: %d %s" id target);
    "Hello, " ^ name ^ ". How was your trip to " ^ city ^ "?"

  let sum a b _ = Printf.sprintf "The sum of %d and %d = %d" a b (a + b)
  let hello _ = "Hello World"
end

let routes =
  let open Routes in
  [ Some `GET, (fun () -> nil) @--> Handlers.hello
  ; Some `GET, (fun () -> s "sum" / int / int /? trail) @--> Handlers.sum
  ; Some `GET, (fun () -> s "greet" / int / str / str /? nil) @--> Handlers.greeter
  ]

let all_route_patterns =
  List.map (fun (_, r) -> Format.asprintf "%a" Routes.pp_route r) routes

let not_found_message =
  let join_routes =
    List.mapi (fun idx r -> Printf.sprintf "%d: %s" (idx + 1) r) all_route_patterns
    |> String.concat "\n"
  in
  Printf.sprintf
    "Route not found. The list of existing route patterns is:\n%s\n"
    join_routes

let request_handler _ reqd =
  let ({ Request.target; meth; _ } as req) = Reqd.request reqd in
  let router = Routes.one_of routes in
  match Routes.match' ~meth ~target router with
  | None -> respond_with_text reqd `Not_found not_found_message
  | Some f -> respond_with_text reqd `OK (f req)

let error_handler _ ?request:_ error start_response =
  let response_body = start_response Headers.empty in
  (match error with
  | `Exn exn ->
    Body.write_string response_body (Printexc.to_string exn);
    Body.write_string response_body "\n"
  | #Status.standard as error ->
    Body.write_string response_body (Status.default_reason_phrase error));
  Body.close_writer response_body

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

let () =
  Logs.set_level (Some Logs.Info);
  Logs.set_reporter @@ Logs_fmt.reporter ();
  let port = ref 8080 in
  Arg.parse
    [ "-p", Arg.Set_int port, " Port number (default is 8080)" ]
    ignore
    "Routing example";
  main !port
