
// SETUP

if (!window.performance || !window.performance.now)
{
	throw new Error('These tests use performance.now() which is not supported by your browser.');
}



// RUNNER


function runBenchmarks(impls, suite, callback)
{
	var frame = document.getElementById('benchmark-frame');
	var results = document.getElementById('benchmark-results');

	frame.style.display = 'block';
	results.style.visibility = 'hidden';
	while (results.lastChild) {
		results.removeChild(results.lastChild);
	}

	runImplementations(impls, suite, 0, function() {
		var canvas = document.createElement('canvas');
		results.appendChild(canvas);
		updateChart(canvas, impls);
		frame.style.display = 'none';
		results.style.visibility = 'visible';
		callback();
	});
}



// RUN IMPLEMENTATIONS


function runImplementations(impls, suite, index, done)
{
	var impl = impls[index];
	var frame = document.getElementById('benchmark-frame');
	frame.onload = function()
	{
		withFacts(0, frame.contentDocument, suite.getFacts, function(facts)
		{
			runSteps(facts, suite.steps, index, 0, [], function(results)
			{
				impl.results = results;
				impl.time = getTotalTime(results);
				console.log(
					impl.name + ' ' + impl.version
					+ (impl.optimized ? ' (optimized)' : '')
					+ ' = ' + trunc(impl.time) + ' ms'
				);

				++index;

				return (index < impls.length)
					? runImplementations(impls, suite, index, done)
					: done();
			});
		});
	}

	frame.src = impl.url;
}


function getTotalTime(results)
{
	var total = 0;
	for (var i = 0; i < results.length; i++)
	{
		total += results[i].sync;
		total += results[i].async;
	}
	return total;
}


function withFacts(tries, doc, getFacts, callback)
{
	if (tries > 5)
	{
		throw new Error('Could not get facts for this implementation.');
	}

	setTimeout(function() {
		var facts = getFacts(doc);
		typeof facts === 'undefined'
			? withFacts(tries + 1, doc, getFacts, callback)
			: callback(facts);
	}, 16 * Math.pow(2, tries));
}



/* RUN STEPS ***/


function runSteps(facts, steps, implIndex, index, results, done)
{
	timedStep(steps[index].work, facts, function(syncTime, asyncTime)
	{
		results.push({
			name: steps[index].name,
			sync: syncTime,
			async: asyncTime
		});

		++index;

		if (index < steps.length)
		{
			return runSteps(facts, steps, implIndex, index, results, done)
		}

		return done(results);
	});
}


function trunc(time)
{
	return Math.round(time);
}


function timedStep(work, facts, callback)
{
	// time all synchronous work
	var start = performance.now();
	work(facts);
	var end = performance.now();
	var syncTime = end - start;

	// time ONE round of asynchronous work
	var asyncStart = performance.now();
	setTimeout(function() {
		var asyncEnd = performance.now();
		callback(syncTime, asyncEnd - asyncStart);
	}, 0);

	// if anyone does more than one round, we do not capture it!
}



/* SETUP WORK LIST *********/


function setupWorklist(suite)
{
	var impls = suite.impls;
	var steps = suite.steps;

	var workList = document.getElementById('work-list');

	while (workList.lastChild)
	{
		workList.removeChild(workList.lastChild);
	}

	for (var i = 0; i < impls.length; i++)
	{
		var impl = document.createElement('li');
		var title = document.createTextNode(impls[i].name);
		impl.appendChild(title);
		workList.appendChild(impl);
	}

	var sidebar = document.getElementById('sidebar');
	sidebar.appendChild(workList);
}



/* DRAW CHARTS *************/


function updateChart(canvas, impls)
{
	new Chart(canvas, {
		type: 'bar',
		data: {
			labels: impls.map(toLabel),
			datasets: [{
				label: 'ms',
				data: impls.map(function(impl) { return trunc(impl.time); }),
				backgroundColor: impls.map(toColor)
			}]
		},
		options: {
			defaultFontFamily: 'Source Sans Pro',
			title: {
				display: true,
				text: 'Benchmark Results',
				fontSize: 20
			},
			legend: {
				display: false
			},
			scales: {
				yAxes: [{
					scaleLabel: {
						display: true,
						labelString: 'Milliseconds (lower is better)',
						fontSize: 16
					},
					ticks: {
						beginAtZero: true
					}
				}]
			}
		}
	});
}

function toLabel(impl)
{
	return impl.name + ' ' + impl.version;
}

function toColor(impl)
{
	return impl.optimized
		? 'rgba(200, 12, 192, 0.5)'
		: 'rgba(75, 192, 192, 0.5)';
}