## Routes &nbsp; [![Actions Status](https://github.com/anuragsoni/routes/workflows/Build/badge.svg)](https://github.com/anuragsoni/routes/actions)

[travis]: https://travis-ci.com/anuragsoni/routes/branches
[travis-img]: https://travis-ci.com/anuragsoni/routes.svg?branch=master

This library will help with adding typed routes to OCaml applications.
The goal is to have a easy to use portable library with
reasonable performance [See benchmark folder](https://github.com/anuragsoni/routes/tree/master/bench).

Users can create a list of routes, and handler function to work
on the extracted entities using the combinators provided by
the library. To perform URL matching one would just need to forward
the URL's path and query to the matcher.

#### Example

```ocaml
# #require "routes";;
# type req = { target: string };;
type req = { target : string; }

# let idx (_ : req) = "root";;
val idx : req -> string = <fun>

# let get_user (id : int) (req : req) = Printf.sprintf "Received request from %s to fetch id: %d" req.target id;;
val get_user : int -> req -> string = <fun>

# let search_user (name: string) (city: string) (_req : req) = "search for user";;
val search_user : string -> string -> req -> string = <fun>

# let routes = Routes.(
    one_of [
      Some `GET, (fun () -> s "" /? nil) @--> idx
    ; Some `GET, (fun () -> s "user" / int /? nil) @--> get_user
    ; Some `POST, (fun () ->  s "user" / str / str /? nil) @--> search_user
    ]);;
val routes : (req -> string) Routes.router = <abstr>

# let req = { target = "/user/12" };;
val req : req = {target = "/user/12"}

# match Routes.match' ~meth:`GET ~target:"/some/url" routes with None -> "No match" | Some r -> r req;;
- : string = "No match"

# match Routes.match' ~meth:`GET ~target:req.target routes with None -> "No match" | Some r -> r req;;
- : string = "Received request from /user/12 to fetch id: 12"

# let my_fancy_route = Routes.(fun () -> s "user" / int / s "add" /? nil);;
val my_fancy_route : unit -> (int -> 'a, 'a) Routes.path = <fun>

# let print_route = Routes.sprintf my_fancy_route;;
val print_route : int -> string = <fun>

# print_route 12;;
- : string = "user/12/add"
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

## Related Work

The combinators are influenced by Rudi Grinberg's wonderful [blogpost](http://rgrinberg.com/posts/primitive-type-safe-routing/) about
type safe routing done via an EDSL using GADTs + an interpreted for the DSL.

Also thanks to Gabriel Radanne for feedback and for the [blog](https://drup.github.io/2016/08/02/difflists/) post showing the technique
used in printf like functions.

