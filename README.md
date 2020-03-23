## Routes &nbsp; [![Actions Status](https://github.com/anuragsoni/routes/workflows/Build/badge.svg)](https://github.com/anuragsoni/routes/actions) [![Coverage Status](https://coveralls.io/repos/github/anuragsoni/routes/badge.svg?branch=master)](https://coveralls.io/github/anuragsoni/routes?branch=master)

This library will help with adding typed routes to OCaml applications.
The goal is to have a easy to use portable library with
reasonable performance [See benchmark folder](https://github.com/anuragsoni/routes/tree/master/bench).

Users can create a list of routes, and handler function to work
on the extracted entities using the combinators provided by
the library. To perform URL matching one would just need to forward
the URL's path to the router.

#### Example

```ocaml
open Routes

let greet_user name id =
  Printf.sprintf "Hello, %s [%d]" name id
;;

let sum a b =
  Printf.sprintf "%d" (a + b)
;;

(* nil and trail are used to indicate the end of a route.
   nil enforces that the route doesn't end with a trailing slash
   as opposed to trail which enforces a final trailing slash. *)
let router =
  one_of [
    s "sum" / int / int /? nil @--> sum
  ; s "user" / str / int /? trail @--> greet_user
  ]
;;

let () =
  match (match' router ~target:"/sum/1/2") with
  | Some "3" -> ()
  | _ -> assert false
;;
```

While the library comes with pattern definitions for some common used types like
int, int32, string, etc, it allows for custom patterns for user-defined types to be
used in the same manner as the pre-defined patterns.

```ocaml
open Routes;;

type shape = Circle | Square

(* a [string -> 'a option] function is needed to define a custom pattern.
   This is what's used by the library to determine whether a path param
   can be successfully coerced into the type or not. *)
let shape_of_string = function
  | "circle" -> Some Circle
  | "square" -> Some Square
  | _ -> None
;;

(* A ['a -> string] function is also needed. This is used when using
   the [sprintf] library function to serialize a route definition into
   a URI target. *)
let shape_to_string = function
  | Circle -> "circle"
  | Square -> "square"
;;

(* When creating a custom pattern, it is recommended to prefix
   the string label with a `:`. This will ensure that when pretty printing
   a route, the output looks consistent with the pretty printers defined
   for the built-in patterns. *)
let shape = pattern shape_to_string shape_of_string ":shape"

let process_shape s = shape_to_string s

let route () = s "shape" / shape / s "create" /? nil

let router = one_of [ route () @--> process_shape ]

let () =
  match' ~target:"/shape/circle/create" router with
  | Some "circle" -> ()
  | _ -> assert false
```

More example of library usage can be seen in the [examples](./example) folder,
and as part of the [test](./test/routing_test.ml) definition.

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

