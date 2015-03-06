# Mongoose Wrangler

Wrangle up some Mongoose and plugins

Mongoose Wrangler takes the guesswork out of managing a mongoose-powered connection to MongoDB. Mongoose provides auto-reconnect and other niceties, but there is still some setup involved. Wrangler attempts to automate as much as possible, including loading of mongoose model definition files.

Mongoose Wrangler can also optionally register commonly-used mongoose plugins such as mongoose-datatable. Other plugins are easily added.

In a nutshell, Mongoose Wrangler was created to handle boilerplate mongoose setup.

## Installation

```bash
$ npm install mongoose-wrangler
```

## Usage

```coffee
MongooseWrangler = require 'mongoose-wrangler'

new MongooseWrangler
  address: "192.168.0.2"
  db: "mydb"
  datatable: true
  modelPath: "./db-models"
```

## Testing

```bash
$ npm test
```

## License

  [MIT](LICENSE)
