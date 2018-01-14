Request = require 'request-promise-native'
{ URL, URLSearchParams } = require 'url'
Path    = require 'path'
util    = require 'util'
MD5     = require 'md5.js'

Property = require './Property'
CError   = require './CoinexError'

HOST = 'https://api.coinex.com'

V1 =  new URL 'v1', 'https://api.coinex.com'
sleep = (secs = 10) =>
  new Promise (resolve, reject) =>
    setTimeout =>
      resolve()
    , secs * 1000

arrayFloat = (arr) ->
  return parseFloat arr if typeof arr is 'string'
  arr.map (element) ->
    if typeof element is 'string' then arrayFloat element else element

dataFloat = (obj) ->
  keys = [
    'amount'
    'avg_price'
    'deal_amount'
    'deal_fee'
    'deal_money'
    'left'
    'maker_fee_rate'
    'price'
    'taker_fee_rate'
  ]
  obj[k] = parseFloat obj[k] for k in keys
  obj.create_time = new Date obj.create_time * 1000
  obj

class Coinex extends Property

  constructor: (@key, @secret) ->
    super()

  get: (path..., search) ->
    uri = new URL HOST
    if typeof search is 'object'
      uri.search = new URLSearchParams search
    else
      path.push search
    uri.pathname = Path.join '/v1', path...
    Request
      url: uri
      json: true
    .then (result) ->
      throw new CError result.code, result.message unless result.code is 0
      result.data

  delete: (path..., search) ->
    uri = new URL HOST
    uri.search = new URLSearchParams search
    uri.pathname = Path.join '/v1', path...
    uri.searchParams.set 'access_id', @key
    uri.searchParams.set 'tonce', new Date().valueOf()
    uri.searchParams.sort()
    uri.searchParams.set 'secret_key', @secret
    md5 = new MD5
    md5.update uri.search.toString().substr(1)  # Lose the leading '?'
    uri.searchParams.delete 'secret_key'
    params =
      ###
      proxy: 'http://localhost:8888'
      insecure: true
      rejectUnauthorized: false
      ###
      uri: uri
      json: true
      method: 'DELETE'
      headers:
        authorization: md5.digest('hex').toUpperCase()
    Request params
    .then (result) ->
      throw new CError result.code, result.message unless result.code is 0
      result.data

  getAuth: (path..., search) ->
    uri = new URL HOST
    uri.search = new URLSearchParams search
    uri.pathname = Path.join '/v1', path...
    uri.searchParams.set 'access_id', @key
    uri.searchParams.set 'tonce', new Date().valueOf()
    uri.searchParams.sort()
    uri.searchParams.set 'secret_key', @secret
    md5 = new MD5
    md5.update uri.search.toString().substr(1)  # Lose the leading '?'
    uri.searchParams.delete 'secret_key'
    params =
      ###
      proxy: 'http://localhost:8888'
      insecure: true
      rejectUnauthorized: false
      ###
      uri: uri
      json: true
      method: 'GET'
      headers:
        authorization: md5.digest('hex').toUpperCase()
    Request params
    .then (result) ->
      throw new CError result.code, result.message unless result.code is 0
      result.data

  post: (path..., params) ->
    uri = new URL HOST
    uri.pathname = Path.join '/v1', path...
    params.access_id = @key
    params.tonce = new Date().valueOf()
    search = new URLSearchParams params
    search.sort()
    search.set 'secret_key', @secret
    md5 = new MD5
    md5.update search.toString()
    Request
      proxy: 'http://localhost:8888'
      insecure: true
      rejectUnauthorized: false
      uri: uri
      json: true
      method: 'POST'
      body: params
      headers:
        authorization: md5.digest('hex').toUpperCase()
    .then (result) ->
      throw new CError result.code, result.message unless result.code is 0
      result.data


  ##################################################################
  ## Market API
  ##################################################################
  
  list: ->
    @get 'market', 'list'

  ticker: (pair) ->
    @get 'market', 'ticker',
      market: pair
    .then (data) =>
      data.ticker

  tickerAll: ->
    @get 'market', 'ticker', 'all'
    .then (data) =>
      data.ticker

  depth: (pair, limit = 100, dp = 8) ->
    merge = if dp then "0.#{'0'.repeat dp - 1}1" else 0
    @get 'market', 'depth',
      market: pair
      merge: merge
      limit: limit
    .then (data) ->
      data.asks = arrayFloat data.asks
      data.bids = arrayFloat data.bids
      data

  transactions: (pair, lastID) ->
    params = market: pair
    params.last_id = lastID if lastID?
    @get 'market', 'deals', params
    .then (data) =>
      for item in data
        amount: parseFloat item.amount
        date: new Date item.date_ms
        price: parseFloat item.price
        type: item.type
        id: item.id

  kline: (pair, type = '1hour') ->
    @get 'market', 'kline',
      market: pair
      type: type
    .then (data) ->
      for item in data
        item[0] = new Date item[0] * 1000
        arrayFloat item

  ##################################################################
  ## Account API
  ##################################################################

  balance: ->
    @getAuth 'balance', {}
    .then (data) =>
      for k, v of data
        v.available = parseFloat v.available
        v.frozen = parseFloat v.frozen
      data

  ##################################################################
  ## Trading API
  ##################################################################

  placeLimitOrder: (pair, type, amount, price, sourceID) ->
    params =
      market: pair
      type: type
      amount: amount.toString()
      price: price.toString()
    params.source_id = sourceID if sourceID
    @post 'order', 'limit', params
    .then (data) ->
      dataFloat data

  placeMarketOrder: (pair, type, amount) ->
    @post 'order', 'market',
      market: pair
      type: type
      amount: amount
    .then (data) ->
      dataFloat data

  cancelOrder: (pair, id) ->
    @delete 'order', 'pending',
      market: pair
      id: id
    .then (data) ->
      dataFloat data

  pending: (pair, page = 1, limit = 100) ->
    @getAuth 'order', 'pending',
      market: pair
      page: page
      limit: limit
    .then (data) ->
      dataFloat order for order in data.data
      data

  finished: (pair, page = 1, limit = 100) ->
    @getAuth 'order', 'finished',
      market: pair
      page: page
      limit: limit
    .then (data) ->
      dataFloat order for order in data.data
      data

  orderStatus: (pair, id) ->
    @getAuth 'order',
      market: pair
      id: id
    .then (data) ->
      dataFloat data

  history: (pair, page = 1, limit = 100) ->
    @getAuth 'order', 'user', 'deals',
      market: pair
      page: page
      limit: limit
    .then (data) ->
      for item in data.data
        item.amount = parseFloat item.amount
        item.deal_money = parseFloat item.deal_money
        item.fee = parseFloat item.fee
        item.price = parseFloat item.price
        item.create_time = new Date item.create_time * 1000
      data


module.exports = Coinex

###

This section to remove.  Just here for initial testing

c = new Coinex 'F42F1492623D47EE861B7150E335AA89',
               '8B678410AF2D46ABB70910D08E4DEAE114F014971E3A4759'

c.list()
.then (data) ->
  console.log data
  c.ticker 'BTCBCH'
.then (data) ->
  console.log data
  c.tickerAll()
.then (data) ->
  console.log data
c.depth 'BTCBCH', 5
.then (data) ->
  console.log data
c.transactions 'BTCBCH', 0
.then (data) ->
  console.log data
c.kline 'BTCBCH'
.then (data) ->
  console.log util.inspect data,
    depth: null
    colors: true
    maxArrayLength: null
c.history 'BTCBCH'
.then (data) ->
  console.log data
c.placeLimitOrder 'CDYBCH', 'buy', 100, 0.00006
.then (data) ->
  console.log data
c.cancelOrder 'CDYBCH', 3418076
.then (data) ->
  console.log data
c.orderStatus 'CDYBCH', 3242404
.then (data) ->
  console.log data
  c.balance()
.then (data) ->
  console.log data

.catch (err) ->
  console.log err.code, err.message

###
