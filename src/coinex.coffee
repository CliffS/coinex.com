Request = require 'request-promise-native'
{ URL } = require 'url'
Path    = require 'path'

Property = require './Property'
CError   = require './CoinexError'

HOST = 'https://api.coinex.com'

V1 =  new URL 'v1', 'https://api.coinex.com'
sleep = (secs = 10) =>
  new Promise (resolve, reject) =>
    setTimeout =>
      resolve()
    , secs * 1000

class Coinex extends Property

  constructor: (@key, @secret) ->
    super()

  get: (path) ->
    path = arguments unless Array.isArray path
    uri = new URL HOST
    uri.pathname = Path.join '/v1', path...
    Request
      url: uri
      json: true
    .then (result) ->
      throw new CError result.code, result.message unless result.code is 0
      result.data

  list: ->
    @get 'market', 'list'

module.exports = Coinex

c = new Coinex
c.list()
.then (data) ->
  console.log data
