## Routes

This library will help with adding typed routes to OCaml applications.

Users can create a list of routes, and handler function to work
on the extracted entities using the combinators provided by
the library. To perform URL matching one would just need to forward
the URL's path and query to the matcher.

The core library in the current state has just one dependency ([Astring](https://github.com/dbuenzli/astring)) and isn't tied
to any particular library or framework. It should be usable in the current state,
but the idea would be to provide sub-libraries with tighter integration with the remaining
ecosystem. Future work would also include working on client side routing for use
with `js_of_ocaml` libraries like [incr_dom](https://github.com/janestreet/incr_dom) or [ocaml-vdom](https://github.com/LexiFi/ocaml-vdom).

#### Example

```ocaml
module Request = struct
  type t
  ...
end

module Response = struct
  type t
  ...
end

let get_user state (id: int) =
  (* Request handlers can define their own routes too *)
  let open Routes in
  let routes = [ int64 </> boolean </> ==> (fun _ i b -> ... ) ] in
  match_with_state ~state routes with
  | None -> ...
  | Some response -> ...

let search_user _ (name: string) (city : string) =
  ...

let routes =
  let open Routes in
  [ empty ==> idx (* matches the index route "/" *)
  ; method' `GET </> s "user" </> int </> empty ==> get_user (* matches "/user/<int>" *)
  ; method' `GET </> s "user" </> str </> str ==> search_user (* missing empty so it matches "/user/<str>/<str>/*" *)
  ]

match Routes.match' routes ~req ~target:"/some/url" ~meth:`GET =
| None -> (* No route matched. Alternative could be to provide default routes *)
| Some r -> (* Match found. Do something further with handler response *)
```

## Installation

`routes` has not been published on OPAM yet. It can be pinned via opam
to use locally:

```
opam pin add routes git+https://github.com/anuragsoni/routes.git
```

## Related Work

The combinators are influenced by Rudi Grinberg's wonderful [blogpost](http://rgrinberg.com/posts/primitive-type-safe-routing/) about
type safe routing done via an EDSL using GADTs + an interpreted for the DSL.

The continuation based approach here is based on:
* Functional Unparsing: https://www.brics.dk/RS/98/12/BRICS-RS-98-12.pdf
* Daniel Patterson's talk on typed routing in haskell: https://dbp.io/talks/2016/fn-continuations-haskell-meetup.pdf
