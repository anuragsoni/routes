(lang dune 3.8)

(name routes)

(using mdx 0.1)

(using melange 0.1)

(generate_opam_files true)

(source
 (github anuragsoni/routes))

(authors "Anurag Soni")

(maintainers "Anurag Soni <anurag@sonianurag.com>")

(documentation "https://anuragsoni.github.io/routes/")

(license BSD-3-clause)

(package
 (name routes)
 (tags
  (router http))
 (depends
  (ocaml
   (>= 4.08.0))
  (base :with-test)
  (stdio :with-test)
  (ppx_expect :with-test)
  (ppx_sexp_conv :with-test)
  (ppx_sexp_value :with-test)
  (ppx_custom_printf :with-test)
  (mdx :with-test)
  (odoc :with-doc))
 (synopsis "Typed routing for OCaml applications")
 (description
   "routes provides combinators for adding typed routing to OCaml applications. The core library will be independent of any particular web framework or runtime. It does path based dispatch from a target url to a user provided handler."))
