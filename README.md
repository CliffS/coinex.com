# coinex.com

[api]: https://github.com/coinexcom/coinex_exchange_api/wiki
[coinex]: https://www.coinex.com/
[coffee2]: https://coffeescript.org/v2/
[apikey]: https://www.coinex.com/apikey

## API Interface for coinex.com Bitcoin Cash exchange.

This module fully implements tha [Coinex][coinex] API. The
full documentation for the API is available on the
[API Wiki Page][api].

It is written in [Coffescript V2][coffee2] using native Promises and
its only dependencies are [bent](https://www.npmjs.com/package/bent)
and [md5.js](https://www.npmjs.com/package/md5.js).
You do not need Coffeescript to use the library; it is pre-compiled to
Javascript ES6.

## Install

```
npm install coinex.com
```

Get your API key and secret key from [here][apikey].

## Example

```javascript
Coinex = require('coinex.com');

const API_KEY = 'F42F1492623D47EE861B7150E335AA89';
const SECRET  = '8B678410AF2D46ABB70910D08E4DEAE114F014971E3A4759'

const coinex = new Coinex(API_KEY, SECRET);

coinex.balance()
.then(response => console.log(response));
.catch(err => console.error(err.code, err.message);
```

## Constructor

```javascript
const coinex = new Coinex(API_KEY, SECRET);
```

## Methods

All the following methods return native Promises which are resolved
on a valid response or rejected on error. Each method returns a
single result object to the `.then()`.

For each method, please see the [API documentation][api].  Below
I have simply documented the call; the response will generally
be the `data` part of the response as documented by [Coinex][api].
If internally Coinex returns an error code of greater than zero,
the promise will be rejected with a [CoinexError](#error-messages).

The returned result will have floating point numbers for values
rather than the string number values returned by the API.  Where a
`pair` is refered to below, it is the *market*, for example `BTCBCH`.

### Market API

#### List Pairs

Returns a list of the available pairs.

```javascript
coinex.list()
```

#### Get Market Data

Get the ticker information for a single pair.

```javascript
coinex.ticker(pair)
```

#### Get All Ticker Data

Get the ticker information for all pairs.

```javascript
coinex.tickerAll()
```

#### Get Market Depth

Get the buy / sell statistics. This will return up to 100
lines and the decimal places can be set between zero and
eight.

```javascript
coinex.depth(pair, [limit], [decimal-places]);
```

If not passed, `limit` is set to 100 and decimal-places is set to
eight.

#### Transaction Data

Get the latest transaction data.  This will return up to 1,000
lines of data.

```javascript
coinex.transactions(pair, [lastID]);
```

#### K-Line Data

Get the k-line data for a specific period, including the last
1,000 data points.

```javascript
coinex.kline(pair, [type]);
```

Type can be one of `1min`, `3min`, `5min`, `15min`, `30min`,
`1hour`, `2hour`, `4hour`,`6hour`,`12hour`, `1day`, `3day`, `1week`.
Type defaults to `1hour` if not passed.

### Account API

#### Get account balance

Returns the balance of each currency currently on the account.

```javascript
coinex.balance()
```

### Trading API

#### Place Limit Order

Places a new order.

```javascript
coinex.placeLimitOrder(pair, type, amount, price, [sourceID]);
```

Type must be `buy` or `sell`.  SourceID is uptional and will be returned
in the response, if provided.

#### Place Market Order

Places a new market order.

```javascript
coinex.placeMarketOrder(pair, type, amount);
```

#### Cancel Order

Cancels an existing order

```javascript
coinex.cancelOrder(pair, id);
```

#### List Pending Orders

This will return a list of orders that have not been filled
nor cancelled.

```javascript
coinex.pending(pair, [page], [limit]);
```

Page defaults to one and limit defaults to 100.  Using the result,
it is possibe to page through many transactions.

#### List Completed Orders

This will return a list of closed orders.  Note that fully cancelled
orders will not appear here.

```javascript
coinex.completed(pair, [page], [limit]);
```

#### Order Status

This returns the status of a single order.

```javascript
coinex.orderStatus(pair, id);
```

#### Deal History

This returns the history of the user's deals for the given pair.

```javascript
coinex.history(pair, [page], [limit]);
```

## Error Messages

API errors are returned as a code and a description.  In this library
they are returned as a class `CoinexError`.  These will work like
normal nodejs errors but should usually be caught with a `.catch(err)`
statement.  For example:

```javascript
coinex.cancelOrder('BTCBCH', 3242404);
.then(data => console.log(data));
.catch(err => console.error(err.code, err.message);
```

## Changes
**v1.0.8** First fully working version
**v1.1.0** Dropped request (deprecated) in favor of bent

## Issues

Please report any bugs or make any suggestions at the
[Github Issue page](https://github.com/CliffS/coinex.com/issues).


