hello = ->
	console.log 'hello from utils...'
foo = ->
	console.log 'foo from utils...'
	
module.exports = {
	hello : hello
	allCows : [{'name': 'Dagros'}, {'name': 'Rosa'}]
}
