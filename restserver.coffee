#Ebay API: https://github.com/newleafdigital/nodejs-ebay-api

restify = require("restify")
kvigedata = require './utils/kvigedata'
bulldata = require './utils/bulldata'
ebay = require './index.js'

class Option
	filters: null
	params: null
	#appId: 'OyvindJo-0763-4567-b70b-0bd840050995' 
	appId: 'OyvindJo-fc9c-4d02-bab0-e19a5e11a5cd'
	constructor: (@serviceName, @opType) ->
	setFilters: (@filters) ->
	setParams: (@params) ->

getEbayRequest = (option, callback) ->
	ebay.ebayApiGetRequest(option, callback)


server = restify.createServer()
server.use restify.bodyParser()

getCows = (req, res, next) ->
	res.send kvigedata.allCows
getBulls = (req, res, next) ->
	res.send bulldata.allBulls

postCow = (req, res, next) ->
	console.log 'postCow: ' + req

createEbayHTML = (items, shippingCosts) ->
  html = '<html><body><table border="1">'
  count = 0
  for item in items
    console.log item
    html = html + '<tr>'
    html = html + '<td>' + item.title + '</td>'
    html = html + '<td><img src="' + item.galleryURL + '"></td>'
    html = html + '<td>$' + item.sellingStatus.currentPrice.USD + '</td>'
    html = html + '<td><a href="' + item.viewItemURL + '">ebay</a></td>'
    html = html + '<td id="shippingCost">' + shippingCosts[count++] + '</td>'
    html = html + '</tr>'

  html = html + '</table></body></html>'
  return html

calculateShippingCosts = (items, callback) ->
  costs = []
  count = 0
  Option option = new Option('','GetShippingCosts')
  for item in items
    costs[count++] = 9
  callback(costs)

callEbay = (req, res, next) ->
	params = {}
	params.keywords = [ "Porsche", "944" ];
	params.categoryId = 6028
	params.descriptionSearch = true
	filters = {}
	filters.itemFilter = [
		new ebay.ItemFilter("FreeShippingOnly", false),
		new ebay.ItemFilter("AvailableTo", 'NO')
	]
	option = new Option('FindingService', 'findItemsAdvanced')
	option.setFilters(filters)
	option.setParams(params)
	getEbayRequest(option, (error, items) ->
    console.log 'got response, error: ' + error + ', items: ' + items
    calculateShippingCosts(items, (shippingCosts) ->
      html = createEbayHTML(items, shippingCosts)
      res.writeHead(200, {
        'Content-Length': Buffer.byteLength(html),
        'Content-Type': 'text/html'
      })
      res.write(html)
      res.end()
    )
  )
			
createError = (err) ->
	console.log 'error: ' + err
	error = new Error(err)
	error.statusCode = 400
	return error

server.get "/cows/aktuelle", getCows
server.get "/bulls", getBulls
server.post "/cows", postCow
server.get "/ebay", callEbay

server.listen 8080, ->
	console.log "%s listening at %s", server.name, server.url

