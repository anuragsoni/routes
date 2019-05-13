# Microbenchmarks for routes

The test data is taken from https://github.com/julienschmidt/go-http-routing-benchmark

License for that can be found httprouter.LICENSE

### Results

* i7-8550U CPU @ 1.80GHz
* OCaml version 4.07.1
* Ubuntu 19.04 (Kernel 5.0.0-13-generic)

```
┌───────────────┬─────────────┬───────────┬──────────┬──────────┬────────────┐
│ Name          │    Time/Run │   mWd/Run │ mjWd/Run │ Prom/Run │ Percentage │
├───────────────┼─────────────┼───────────┼──────────┼──────────┼────────────┤
│ Static Bench  │ 44_312.84ns │ 6_464.13w │    0.34w │    0.34w │    100.00% │
│ Github Static │    132.96ns │    40.00w │          │          │      0.30% │
│ Github Params │    314.81ns │   101.00w │          │          │      0.71% │
│ Parse Static  │    127.66ns │    40.00w │          │          │      0.29% │
│ Parse 1 param │    179.67ns │    67.00w │          │          │      0.41% │
│ Parse 2 param │    294.31ns │    99.00w │          │          │      0.66% │
└───────────────┴─────────────┴───────────┴──────────┴──────────┴────────────┘
```

* Static bench: Collection of random 157 routes. Runs 157 urls through the router in every run.
* Parse: Collection of routes from the Parse.com api
* Github: Collection of routes from the github API


Note: The benchmarks don't represent all routing situations.
Please run your own tests on the routes you are most likely to define.
