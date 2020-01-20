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
open Routes

let sum a b = Printf.sprintf "Sum of %d and %d = %d" a b (a + b)
let id_handler id = Printf.sprintf "Requested user with id %d" id
let admin_handler a = if a then "User is admin" else "User is not an admin"
let route r = None, r
let user () = s "user"
let user_and_id () = user () / int /? nil
let user_and_admin () = user () / bool /? nil
let q () = s "confusing" /? nil

let routes =
  one_of
    [ route @@ (fun () -> s "hi" /? nil) @--> "Hello, World"
    ; route @@ (fun () -> s "hello" / s "from" / s "routes" /? nil) @--> "Hello, Routes"
    ; route @@ (fun () -> s "sum" / int / int /? nil) @--> sum
    ; route @@ user_and_id @--> id_handler
    ; route @@ user_and_admin @--> admin_handler
    ; route @@ q @--> "Foobar"
    ]
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

# let shape = pattern shape_to_string shape_of_string
val shape : ('_weak1, '_weak2) path -> (shape -> '_weak1, '_weak2) path =
  <fun>

# let process_shape (s : shape) = shape_to_string s
val process_shape : shape -> string = <fun>

# let route () = s "shape" / shape / s "create" /? nil
val route : unit -> (shape -> '_weak3, '_weak3) path = <fun>

# sprintf route
- : shape -> string = <fun>

# sprintf route Square
- : string = "shape/square/create"

# let router = one_of [ None, route @--> process_shape ]
val router : string router = <abstr>

# match' ~target:"/shape/circle/create" router
- : string option = Some "circle"

# match' ~target:"/shape/square/create" router
- : string option = Some "square"

# match' ~target:"/shape/triangle/create" router
- : string option = None
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

## Documentation by version

- [trunk](trunk)
- [0.6.0](0.6.0)
- [0.5.2](0.5.2)
