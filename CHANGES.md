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
