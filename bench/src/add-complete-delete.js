
var suite = function() {


// FACTS

function getFacts(doc)
{
	var input = doc.getElementsByClassName('new-todo')[0];
	return input ? { doc: doc, input: input } : undefined;
}


// STEPS

function addCompleteDeleteSteps(numItems)
{
	var steps = [];

	for (var i = 0; i < numItems; i++)
	{
		steps.push({ name: 'Inputing ' + i, work: inputTodo(i) });
		steps.push({ name: 'Entering ' + i, work: pressEnter });
	}

	for (var i = 0; i < numItems; i++)
	{
		steps.push({ name: 'Checking ' + i, work: click('toggle', i) });
	}

	for (var i = 0; i < numItems; i++)
	{
		steps.push({ name: 'Removing ' + i, work: click('destroy', 0) });
	}

	return steps;
}

function inputTodo(number)
{
	return function(facts)
	{
		var node = facts.input;

		var inputEvent = document.createEvent('Event');
		inputEvent.initEvent('input', true, true);
		node.value = 'Do task ' + number;
		node.dispatchEvent(inputEvent);
	};
}

function pressEnter(facts)
{
	var event = document.createEvent('Event');
	event.initEvent('keydown', true, true);
	event.key = 'Enter';
	event.keyCode = 13;
	event.which = 13;
	facts.input.dispatchEvent(event);
	facts.input.click();

	var ev = document.createEvent('Event');
	ev.initEvent('keyup', true, true);
	ev.key = 'Enter';
	ev.keyCode = 13;
	ev.which = 13;
  	facts.input.dispatchEvent(ev);
	facts.input.click();
}

function click(className, index)
{
	return function(facts)
	{
		facts.doc.getElementsByClassName(className)[index].click();
	};
}


// SUITE

return {
	getFacts: getFacts,
	steps: addCompleteDeleteSteps(150)
};


}();
