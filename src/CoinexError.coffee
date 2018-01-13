

class CoinexError extends Error

  constructor: (@code, message) ->
    super message
    Error.captureStackTrace @, CoinexError

module.exports = CoinexError
