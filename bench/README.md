# Microbenchmarks for routes

The test data is taken from https://github.com/julienschmidt/go-http-routing-benchmark

License for that can be found httprouter.LICENSE

### Results

* i7-8550U CPU @ 1.80GHz
* OCaml version 4.08.1+flambda
* Ubuntu 19.04 (Kernel 5.0.0-27-generic)

```
    Name               Time/Run     mWd/Run   mjWd/Run   Prom/Run   Percentage
 --------------- ------------- ----------- ---------- ---------- ------------
  Static Bench    26_729.04ns   6_119.12w      4.52w      4.52w      100.00%
  Github Static      103.85ns      35.00w                              0.39%
  Github Params      201.25ns      88.00w                              0.75%
  Parse Static        91.54ns      35.00w                              0.34%
  Parse 1 param      118.92ns      58.00w                              0.44%
  Parse 2 param      220.28ns      86.00w                              0.82%
```

* Static bench: Collection of random 157 routes. Runs 157 urls through the router in every run.
* Parse: Collection of routes from the Parse.com api
* Github: Collection of routes from the github API


Note: The benchmarks don't represent all routing situations.
Please run your own tests on the routes you are most likely to define.

