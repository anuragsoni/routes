## Routes &nbsp; [![Actions Status](https://github.com/anuragsoni/routes/workflows/Build/badge.svg)](https://github.com/anuragsoni/routes/actions)

This library will help with adding typed routes to OCaml applications.
The goal is to have a easy to use portable library with
reasonable performance [See benchmark folder](https://github.com/anuragsoni/routes/tree/master/bench).

Users can create a list of routes, and handler function to work
on the extracted entities using the combinators provided by
the library. To perform URL matching one would just need to forward
the URL's path and query to the matcher.

## Installation

###### To use the version published on opam:
```
opam install routes
```

###### For development version:
```
opam pin add routes git+https://github.com/anuragsoni/routes.git
```

## Documentation by version

- [trunk](trunk)
- [0.6.0](0.6.0)
- [0.5.2](0.5.2)
