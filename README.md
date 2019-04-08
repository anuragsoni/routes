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

let get_user (id: int) () =
  ...

let search_user (name: string) (city : string) () =
  ...

let routes =
  let open Routes in
  [ s "" ==> fun () - ... (* matches the index route "/" *)
  ; (method' (Some `GET)) (s "user" </> int) ==> get_user (* matches "/user/<int>" *)
  ; method' None (s "user" </> str </> str) ==> search_user (*  matches "/user/<str>/<str>" *)
  ]

match Routes.match' routes ~target:"/some/url" ~meth:`GET =
| None -> (* No route matched. Alternative could be to provide default routes *)
| Some r -> (* Match found. Do something further with handler response *)
```

`Routes` also provides a sprintf like function to generate formatted URLs. It uses
the same format description of a route that is used for routing.

```ocaml
utop # let route = method' None (s "foo" </> int </> str </> bool);;
- : val route : (int -> string -> bool -> unit -> '_weak1, '_weak1) route =
  Route (None, S ("foo", S ("/", Int (S ("/", Str (S ("/", Bool End)))))))

utop # sprintf route;;
- : int -> string -> bool -> unit -> string = <fun>

utop # (sprintf route) 12 "bar" false ();;
- : string = "foo/12/bar/false"
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

Also thanks to Gabriel Radanne for feedback and for the [blog](https://drup.github.io/2016/08/02/difflists/) post showing the technique
used in printf like functions.
