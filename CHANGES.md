# 2.0.0

* use `ppx_expect` for tests

## Breaking changes

* Drop support for OCaml 4.05-4.07
* Switch to a new model for trailing slash handling. In routes 1.0.0 users needed to be careful about using `/?` and `//?` as the former would only match routes without a trailing slash, and the latter would enforce a trailing slash.
  - Users only need to use `/?` to end routes, and it will cover both routes ending with trailing slashes and without
  - The type used for representing match results has more information about whether it was an exact match, or if it was a match but the input target had a trailing slash at the end.
  - `MatchWithTrailingSlash` informs the user that the current target was considered a match, but that the target has an additional trailing slash

# 1.0.0

* First major release. No changes from 0.9.1

# 0.9.1

* bucklescript: Use correct version number (0.9.1) in package.json

# 0.9.0

* Add a labelled function to create custom patterns (#114)
* Add support for union operation for two routers (#115, @Chattered)
* Use dune language 2.0 (#116)
* Support wildcard pattern at the end of a route (#118, #129, @Lupus)
* Add map and path prefix to route targets (#121, @Chattered)
* Make ksprintf visible in the public api (#123, @Chattered)

# 0.8.0

* Improve trailing slash handling. Instead of separate `nil` and `trail` constructors, all routes end with `nil`.
  The trailing slash is controlled via `/?` for no trailing slash, and `//?` for trailing slash. (#111)
* No longer possible to use `nil` unless it follows a pattern. To create a route that matches no path params, ex: "/"
  use `empty`. (#111)

# 0.7.3

* Allow adding new routes to existing router. (#108, @tatchi)
* Fix library name in bsconfig.json. (#109, @tsnobip)
* Specify -O3 flag for ocamlopt when using dune's release profile. (#110)

# 0.7.2

* Use bisect_ppx to generate coverage reports (#95)
* Lower version constraint for dune and ocaml. Minimum versions needed are now dune 1.0 and OCaml 4.05.0 (#99, #100)

# 0.7.1
**Note**: 0.7.2 has the same content as 0.7.1 except for a dune file change needed for bisect_ppx
* Use bisect_ppx to generate coverage reports (#95)
* Lower version constraint for dune and ocaml. Minimum versions needed are now dune 1.0 and OCaml 4.05.0 (#99, #100)

# 0.7.0

This is a breaking release:

* Reduce the number of combinators to two. '/' and '/?' (#80)
* Routes are now bi-directional. They can be used for matching, and for printing via a sprintf style function (#80)
* Its now possible to configure trailing slash on individual routes (#89)
* Remove HTTP method handling (#92)
* dune version needs to be >= 2.1

# 0.6.0

* Improve mdx test tules (#73, @NathanReb)
* Use github actions instead of travis ci (#70, #72)
* Get human readable route pattern from a route (#64, #74)
* Allow writing custom path match patterns (#76)

# 0.5.2

* Support custom HTTP methods via `Other of string` (#58 , @sazarkin)

# 0.5.1

* Allow user to decide if they want to keep or ignore trailing slash (#50)

# 0.5.0

* Flatten nested skip-left actions.
* Group routes based on the HTTP verb.
* Use a trie based path matcher.
* Add micro-benchmark suite.

# 0.4.2

* Specialize apply for `SkipLeft` parsers.
* Re-write routes for better matches.

# 0.4.1

* Remove `stdcompat` (#33)
* Add example using [opium](https://github.com/rgrinberg/opium) (#34)

# 0.4.0

* Switch to using an applicative functor as parser. (#27)
* Have a version of matching without HTTP methods. (#27)
* Tokenize the path parameters into list of strings. (#27)
* Add more tests for matchers. (#28)
* `s` now returns the string it matches, instead of discarding it. (#29)

# 0.3.0

* Extract string operations to its own module (#14)
* Drop dependency on astring (#16)
* Add pretty printers for utop (#18)
* Accept a request that is in-turn forwarded to handlers (#22)
* Use `mdx` to test examples in the readme file (#23)

# 0.2.0

* Switched to a GADT representation of routes
* Add support for using the same route type for both parsing and a sprintf like function

# 0.1.0

* Initial version of router
