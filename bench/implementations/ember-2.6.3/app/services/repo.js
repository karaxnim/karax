import Ember from 'ember';

export default Ember.Service.extend({
	lastId: 0,
	data: null,
	findAll() {
		return this.get('data') || this.set('data', []);
	},

	add(attrs) {
		let todo = Object.assign({ id: this.incrementProperty('lastId') }, attrs);
		this.get('data').pushObject(todo);
		return todo;
	},

	delete(todo) {
		this.get('data').removeObject(todo);
	}
});
