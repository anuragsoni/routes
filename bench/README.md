# Microbenchmarks for routes

The test data is taken from https://github.com/julienschmidt/go-http-routing-benchmark

License for that can be found httprouter.LICENSE

### Results

* i7-8550U CPU @ 1.80GHz
* OCaml version 4.07.1
* Ubuntu 19.04 (Kernel 5.0.0-13-generic)

```
 Name               Time/Run     mWd/Run   mjWd/Run   Prom/Run   Percentage
 --------------- ------------- ----------- ---------- ---------- ------------
  Static Bench    27_767.11ns   5_834.12w      4.20w      4.20w      100.00%
  Github Static      109.61ns      33.00w                              0.39%
  Github Params      203.99ns      86.00w                              0.73%
  Parse Static        86.91ns      33.00w                              0.31%
  Parse 1 param      120.73ns      56.00w                              0.43%
  Parse 2 param      208.58ns      84.00w                              0.75%
```

* Static bench: Collection of random 157 routes. Runs 157 urls through the router in every run.
* Parse: Collection of routes from the Parse.com api
* Github: Collection of routes from the github API


Note: The benchmarks don't represent all routing situations.
Please run your own tests on the routes you are most likely to define.
