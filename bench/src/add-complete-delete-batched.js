
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
	return [
		{
			name: 'Adding ' + numItems + ' Items',
			work: add(numItems)
		},
		{
			name: 'Completing All Items',
			work: clickAll('.toggle')
		},
		{
			name: 'Deleting All Items',
			work: clickAll('.destroy')
		}
	];
}

function add(numItems)
{
	return function(facts)
	{
		var node = facts.input;

		for (var i = 0; i < numItems; i++)
		{
			var inputEvent = document.createEvent('Event');
			inputEvent.initEvent('input', true, true);
			node.value = 'Do task ' + i;
			node.dispatchEvent(inputEvent);

			var keydownEvent = document.createEvent('Event');
			keydownEvent.initEvent('keydown', true, true);
			keydownEvent.keyCode = 13;
			node.dispatchEvent(keydownEvent);
		}
	};
}

function clickAll(selector)
{
	return function(facts)
	{
		var checkboxes = facts.doc.querySelectorAll(selector);
		for (var i = 0; i < checkboxes.length; i++)
		{
			checkboxes[i].click();
		}
	};
}


// SUITE

return {
	getFacts: getFacts,
	steps: addCompleteDeleteSteps(100)
};


}();