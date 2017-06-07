# Angular TodoMVC for Benchmarking

This is an update of the
_[Angular TodoMVC example](https://github.com/tastejs/todomvc/tree/gh-pages/examples/angularjs-perf)_
with the following changes:

* Upgrade to Angular 1.5.7
* Update todomvc-app-css to 2.0.6 to match other examples in this benchmark
* Remove localStorage functionality - not relevant to measuring render performance
* Concat JS into one file
* Minify with uglify

This example is listed as "performance optimized" in the TodoMVC repository, but doesn't appear to make any performance improvements to the basic example other than excluding all features not mentioned in the app specification. Therefore, it should count as having no optimizations for the purposes of this benchmark.

# Building

1. `npm install`
2. `npm run make`
3. Open a local server (e.g. with `npm install -g http-server`) and open index.html
