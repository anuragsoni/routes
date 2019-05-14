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
  Static Bench    30_263.57ns   5_842.11w      0.29w      0.29w      100.00%
  Github Static      104.07ns      36.00w                              0.34%
  Github Params      238.18ns      89.00w                              0.79%
  Parse Static        92.69ns      36.00w                              0.31%
  Parse 1 param      140.63ns      59.00w                              0.46%
  Parse 2 param      238.72ns      87.00w                              0.79%
```

* Static bench: Collection of random 157 routes. Runs 157 urls through the router in every run.
* Parse: Collection of routes from the Parse.com api
* Github: Collection of routes from the github API


Note: The benchmarks don't represent all routing situations.
Please run your own tests on the routes you are most likely to define.
