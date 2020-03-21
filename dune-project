(lang dune 2.1)

(name routes)

(generate_opam_files true)

(source
 (github anuragsoni/routes))

(documentation
  https://anuragsoni.github.io/routes/)

(authors "Anurag Soni <anurag@sonianurag.com>")

(maintainers "Anurag Soni <anurag@sonianurag.com>")

(license BSD-3-clause)

(package
 (name routes)
 (synopsis "Typed routing for OCaml applications")
 (tags
  ("router" "http"))
 (description
   "routes provides combinators for adding typed routing\nto OCaml applications. The core library will be independent\nof any particular web framework or runtime. It does\npath based dispatch from a target url to a user\nprovided handler.\n")
 (depends
  (ocaml
   (>= 4.06.1))
  (dune
   (>= 2.1))
  (alcotest :with-test)
  (mdx :with-test)))
