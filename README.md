## Routes

This library will help with adding typed routes to OCaml applications.

Users can create a list of routes, and handler function to work
on the extracted entities using the combinators provided by
the library. To perform URL matching one would just need to forward
the URL's path and query to the matcher.

The core library in the current state isn't tied to any particular library or framework.
It should be usable in the current state, but the idea would be to provide sub-libraries
with tighter integration with the remaining ecosystem. Future work would also include
working on client side routing for use with `js_of_ocaml` libraries
like [incr_dom](https://github.com/janestreet/incr_dom) or [ocaml-vdom](https://github.com/LexiFi/ocaml-vdom).

#### Example

```ocaml
# #require "routes";;
# open Routes;;
# open Infix;;
# type req = {target: string};;
type req = { target : string; }

# let idx (_ : req) = "root";;
val idx : req -> string = <fun>

# let get_user (id: int) (req : req) = Printf.sprintf "Received request from %s to fetch id: %d" req.target id
val get_user : int -> req -> string = <fun>

# let search_user (name: string) (city : string) (_req : req) = "search for user";;
val search_user : string -> string -> req -> string = <fun>

# let routes =
  with_method [ `GET, idx <$ s "" (* matches the index route "/" *)
  ; `GET, get_user <$> s "user" *> int (* matches "/user/<int>" *)
  ; `POST, search_user <$> s "user" *> str </> str (*  matches "/user/<str>/<str>" *)
  ]
val routes : (req -> string) router = <abstr>

# let req = { target = "/user/12" };;
val req : req = {target = "/user/12"}

# match Routes.match_with_method routes ~target:"/some/url" ~meth:`GET with None -> "No match" | Some r -> r req;;
- : string = "No match"

# match Routes.match_with_method routes ~target:req.target ~meth:`GET with None -> "No match" | Some r -> r req;;
- : string = "Received request from /user/12 to fetch id: 12"
```

## Installation

###### To use the version published on opam:
```
opam install routes
```

###### For development version:
```
opam pin add routes git+https://github.com/anuragsoni/routes.git
```

## Example use inside other libraries:

* Httpaf -> [example/main.ml](https://github.com/anuragsoni/routes/blob/3d7d25e11be0f13d855cad4c659944c0ebb6ec52/example/main.ml)
* Opium -> [example/opium_example.ml](https://github.com/anuragsoni/routes/blob/3d7d25e11be0f13d855cad4c659944c0ebb6ec52/example/opium_example.ml)

## Related Work

The combinators are influenced by Rudi Grinberg's wonderful [blogpost](http://rgrinberg.com/posts/primitive-type-safe-routing/) about
type safe routing done via an EDSL using GADTs + an interpreted for the DSL.

Also thanks to Gabriel Radanne for feedback and for the [blog](https://drup.github.io/2016/08/02/difflists/) post showing the technique
used in printf like functions.
