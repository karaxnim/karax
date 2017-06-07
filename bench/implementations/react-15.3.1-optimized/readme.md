# React TodoMVC for Benchmarking

This is an update of the React TodoMVC example to use React 15.1 and
precompiled/minified JSX instead of the slow JSXTransformer. The idea is that
this is a reasonable approximation of the performance characteristics of modern
production React code.

This is not a perfect reflection of React best practices, because there is no
such thing. If you ask five professional React users what current React best
practices are, you'll get five different answers—each of which will benchmark
differently. React Router, Immutable.js, Redux (with or without sagas), Ramda,
ES2015 (with various Babel plugins), Webpack...the list never ends.

Rather than wading into that combinatorial explosion, this example is leaving
the original React TodoMVC implementation's supporting stack alone, and only
performing the following upgrades:

* Upgrade to React 15.1
* Move everything into one JSX file and precompile it with Babel
* Minify with uglify

If you're curious how it benchmarks with your particular stack, please fork
this repo and find out!

# Building

1. `npm install`
2. `npm run make`
3. Open a local server (e.g. with `npm install -g http-server`) and open index.html


