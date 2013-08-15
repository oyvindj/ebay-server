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

callEbay = (option, callback) ->
  #console.log 'calling ebay with option: ' + option
	ebay.ebayApiGetRequest(option, (error, data) ->
    console.log 'got response'
    console.log 'error: ' + error
    if(data != undefined)
      #console.log 'data: ' + data
      console.log("data: %j", data)
      #console.log ebay.flatten(data)

    callback(error, data)
  )


server = restify.createServer()
server.use restify.bodyParser()

getCows = (req, res, next) ->
	res.send kvigedata.allCows
getBulls = (req, res, next) ->
	res.send bulldata.allBulls

postCow = (req, res, next) ->
	console.log 'postCow: ' + req

sortByDate = (a, b) ->
  aName = new Date(a.listingInfo.startTime)
  bName = new Date(b.listingInfo.startTime) 
  ret = 0
  if(aName.getTime() < bName.getTime())
    ret = 1
  else if(aName.getTime() > bName.getTime())
    ret = -1
  return ret
  
createEbayHTML = (inItems, shippingCosts) ->
  items = inItems.sort(sortByDate)
  html = '<html><body><table border="1">'
  html = html + '<tr><td>Found' + items.length + ' items</td></tr>'
  count = 0
  now = new Date()
  for item in items
    html = html + '<tr>'
    html = html + '<td><table><tr><td>' + item.title + '</td></tr><tr><td>' + '&nbsp;' + '</td></tr></table></td>'
    html = html + '<td><img src="' + item.galleryURL + '"></td>'
    html = html + '<td>$' + item.sellingStatus.currentPrice.USD + '</td>'
    html = html + '<td><a href="' + item.viewItemURL + '">ebay</a></td>'
    html = html + '<td id="shippingCost">' + shippingCosts[count++] + '</td>'
    html = html + '<td>' + item.listingInfo.buyItNowAvailable + '</td>'
    startTime = new Date(item.listingInfo.startTime)
    endTime = new Date(item.listingInfo.endTime)
    diffTime = now - startTime
    diffTimeMinutes = Math.floor(diffTime / 1000 / 60)
    diffTimeHours = Math.floor(diffTime / 1000 / 60 / 60)
    diffTimeDays = Math.floor(diffTimeHours / 24)
    html = html + '<td>' + startTime.getDate() + '/' + (startTime.getMonth() + 1) + '</td>'
    html = html + '<td>' + diffTimeMinutes + ' mins (' + diffTimeDays + 'd)</td>'
    html = html + '<td>' + endTime.getDate() + '/' + (endTime.getMonth() + 1) + '</td>'
    html = html + '</tr>'

  html = html + '</table></body></html>'
  return html

getShippingCosts = (items, callback) ->
  costs = []
  for item in items
    costs.push 9
  callback('', costs)

getShippingCosts2 = (items, callback) ->
  console.log 'calculating shipping for items'
  costs = []
  resultCount = 0
  index = 0
  shippingOption = new Option('Shopping','GetShippingCosts')
  for item in items
    console.log 'making shipping cost call for item: ' + item.itemId
    params = {}
    params.ItemID = item.itemId
    params.DestinationCountryCode = 'NO'
    params.DestinationPostalCode = '1903'
    params.IncludeDetails = true
    params.MessageID = item.itemId
    paginationInput = {}
    paginationInput.entriesPerPage = 3
    params.paginationInput = paginationInput
    shippingOption.setParams(params)
    callEbay(shippingOption, (error, shippingCost) ->
      console.log 'got shipping call response'
      resultCount++
      costs[index] = shippingCost;
      if((error.length == 0) && (resultCount == items.length))
        console.log 'got all shipping costs'
        callback(costs)
    )
    index++

getEbayItems = (items, callback) ->
  console.log 'getting ebay items...'
  costs = []
  resultCount = 0
  index = 0
  option = new Option('Shopping','GetSingleItem')
  for item in items
    console.log 'making call for item: ' + item.itemId
    params = {}
    params.ItemID = item.itemId
    params.MessageID = index
    option.setParams(params)
    callEbay(option, (error, ebayItem) ->
      console.log 'got ebay item response: ' + ebayItem
      costs[resultCount++] = ebayItem[0];
      if(resultCount == items.length)
        console.log 'got all ebay items'
        callback(costs)
    )
    index++

getEbay = (req, res, next) ->
  params = {}
  params.keywords = [ "Porsche", "944" ];
  params.categoryId = 6028
  params.descriptionSearch = true
  filters = {}
  filters.itemFilter = [
    new ebay.ItemFilter("FreeShippingOnly", false),
    new ebay.ItemFilter("AvailableTo", 'NO')
    #new ebay.AspectFilter("MaxItems", 3)
  ]
  option = new Option('FindingService', 'findItemsAdvanced')
  option.setFilters(filters)
  option.setParams(params)
  callEbay(option, (error, items) ->
    getShippingCosts(items, (shippingCosts) ->
      console.log 'got shipping cost'
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
server.get "/ebay", getEbay

server.listen 8089, ->
	console.log "%s listening at %s", server.name, server.url

