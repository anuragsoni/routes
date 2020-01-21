# Microbenchmarks for routes

The test data is taken from https://github.com/julienschmidt/go-http-routing-benchmark

License for that can be found httprouter.LICENSE

### How to run?

```
* opam install core_bench
* dune build bench/main.exe --profile=release
* ./_build/default/bench/main.exe
```

