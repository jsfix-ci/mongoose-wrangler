# Mongoose Wrangler

Wrangle up some Mongoose and plugins

Mongoose Wrangler takes the guesswork out of managing a mongoose-powered connection to MongoDB. Mongoose provides auto-reconnect and other niceties, but there is still some setup involved. Wrangler attempts to automate as much as possible, including loading of mongoose model definition files.

Mongoose Wrangler can also optionally register commonly-used mongoose plugins such as mongoose-datatable. Other plugins are easily added, so send in those PRs.

In a nutshell, Mongoose Wrangler was created to handle boilerplate mongoose setup.

## Installation

```bash
$ npm install mongoose-wrangler
```

## Usage

```coffee
MongooseWrangler = require 'mongoose-wrangler'

# initialize with options
mw = new MongooseWrangler
  debug: true              # default: false
  address: "192.168.0.2"   # default: "127.0.0.1"
  db: "mydb"               # default: "test"
  datatable: true          # default: false
  modelPath: "./db-models" # default: "./models"

# manually disconnect
mw.disconnect()
```

Depending on the project setup, using `mongoose = require('mongoose')` may point to a different instance of mongoose. To access the mongoose instance used by mongoose-wrangler:

```coffee
mongoose = require('mongoose-wrangler').mongoose
```

### Debug

Using the `debug: true` option will print out a little more information such as each model as it is loaded.

## Testing

```bash
$ npm test
```

## License

  [MIT](LICENSE)
