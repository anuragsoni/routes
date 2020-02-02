## Routes &nbsp; [![Actions Status](https://github.com/anuragsoni/routes/workflows/Build/badge.svg)](https://github.com/anuragsoni/routes/actions)

### Note: This library is undergoing some restructuring. If you need something that is available on opam, refer to the 0.6.0 release located at https://github.com/anuragsoni/routes/tree/0.6.0

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
      Some `GET, nil @--> idx
    ; Some `GET, (s "user" / int /? nil) @--> get_user
    ; Some `POST, (s "user" / str / str /? trail) @--> search_user
    ]);;
val routes : (req -> string) Routes.router = <abstr>

# let req = { target = "/user/12" };;
val req : req = {target = "/user/12"}

# match Routes.match' ~meth:`GET ~target:"/some/url" routes with None -> "No match" | Some r -> r req;;
- : string = "No match"

# match Routes.match' ~meth:`GET ~target:req.target routes with None -> "No match" | Some r -> r req;;
- : string = "Received request from /user/12 to fetch id: 12"

# match Routes.match' ~meth:`POST ~target:"/user/hello/world/" routes with None -> "No match" | Some r -> r req;;
- : string = "search for user"

# match Routes.match' ~meth:`POST ~target:"/user/hello/world" routes with None -> "No match because of missing trailing slash" | Some r -> r req;;
- : string = "No match because of missing trailing slash"

# let my_fancy_route () = Routes.(s "user" / int / s "add" /? nil);;
val my_fancy_route : unit -> (int -> 'a, 'a) Routes.path = <fun>

# let print_route = Routes.sprintf @@ my_fancy_route ();;
val print_route : int -> string = <fun>

# print_route 12;;
- : string = "/user/12/add"
```

It is possible to define custom patterns that can be used for matching.

```ocaml
# open Routes;;
# type shape = Circle | Square
type shape = Circle | Square

# let shape_of_string = function "circle" -> Some Circle | "square" -> Some Square | _ -> None
val shape_of_string : string -> shape option = <fun>

# let shape_to_string = function Circle -> "circle" | Square -> "square"
val shape_to_string : shape -> string = <fun>

# let shape = pattern shape_to_string shape_of_string ":shape"
val shape : ('_weak1, '_weak2) path -> (shape -> '_weak1, '_weak2) path =
  <fun>

# let process_shape (s : shape) = shape_to_string s
val process_shape : shape -> string = <fun>

# let route () = s "shape" / shape / s "create" /? nil
val route : unit -> (shape -> '_weak3, '_weak3) path = <fun>

# sprintf (route ())
- : shape -> string = <fun>

# sprintf (route ()) Square
- : string = "/shape/square/create"

# let router = one_of [ None, route () @--> process_shape ]
val router : string router = <abstr>

# match' ~target:"/shape/circle/create" router
- : string option = Some "circle"

# match' ~target:"/shape/square/create" router
- : string option = Some "square"

# match' ~target:"/shape/triangle/create" router
- : string option = None

# Format.asprintf "%a" pp_path (route ())
- : string = "/shape/:shape/create"
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

