Request = require 'request-promise-native'
{ URL, URLSearchParams } = require 'url'
Path    = require 'path'
util    = require 'util'

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
    console.log uri.toString()
    Request
      url: uri
      json: true
    .then (result) ->
      throw new CError result.code, result.message unless result.code is 0
      result.data

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

module.exports = Coinex

c = new Coinex
###
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
###
c.kline 'BTCBCH'
.then (data) ->
  console.log util.inspect data,
    depth: null
    colors: true
    maxArrayLength: null

.catch (err) ->
  console.log err.code, err.message
