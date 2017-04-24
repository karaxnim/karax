# Ember.js TodoMVC for Benchmarking

This is an update of the
_[Ember.js TodoMVC example](https://github.com/tastejs/todomvc/tree/gh-pages/examples/emberjs)_
with the following changes:

* Upgrade to Ember 2.6.2
* Configure router to support relative URLs
* Remove localStorage functionality - not relevant to measuring render performance

# Building

1. `npm install`
2. `npm run make`
3. `open dist/index.html`
