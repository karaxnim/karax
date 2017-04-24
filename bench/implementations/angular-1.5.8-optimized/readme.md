# Angular TodoMVC for Benchmarking

This is an update of the
_[Angular TodoMVC example](https://github.com/tastejs/todomvc/tree/gh-pages/examples/angularjs-perf)_
with the following changes:

* Upgrade to Angular 1.5.7
* Update todomvc-app-css to 2.0.6 to match other examples in this benchmark
* Remove localStorage functionality - not relevant to measuring render performance
* Concat JS into one file
* Minify with uglify

and additional performance optimizations:

#### Removed the deep $watch in favor of direct function calls
The original example uses $scope.$watch with object equality enabled to track changes to the array of todos and perform actions when changes are detected. This is not a good practice as it causes a deep array comparison to happen every digest cycle, which can significantly degrade performance when working with large collections. Instead we can perform the required actions directly whenever todos are modified, since we control all points of possible modification.

#### Removed "track by $index" from the ng-repeat directive
The original example uses the ng-repeat directive with a "track by $index" clause to display the list of todos. _[Refer to section "Tracking and Duplicates" here for information on using "track by".](https://code.angularjs.org/1.5.7/docs/api/ng/directive/ngRepeat)_ In this particular case it is not necessary to use it, as long as care is taken not to persist the "$$hashKey" property added by Angular to local storage, which would cause duplicates to appear when the collection is loaded and new items are added, triggering an exception. The version without the "track by" clause could reasonably be written by someone implementing this from scratch and demonstrates better performance.

# Building

1. `npm install`
2. `npm run make`
3. Open a local server (e.g. with `npm install -g http-server`) and open index.html
