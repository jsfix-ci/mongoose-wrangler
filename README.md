# Mongoose Wrangler

Wrangle up some Mongoose and plugins

Mongoose Wrangler takes the guesswork out of managing mongoose-powered connections to MongoDB. Mongoose provides auto-reconnect and other niceties, but there is still some setup involved, especially with multiple connections. Wrangler attempts to automate as much as possible, including loading of mongoose model definition files for each connection.

Mongoose Wrangler can also optionally register commonly-used mongoose plugins such as mongoose-datatable and gridfs-stream. Other plugins are easily added, so send in those PRs.

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
  gridfs: true             # default: false
  modelPath: "./db-models" # default: "./models"
  additional: [            # optional array of additional connections
    address: "127.0.0.1"
    db: "otherDb"
    modelPath: "./other"   # models to load specifically for additional connection
  ]

# manually disconnect
mw.disconnect()
```

Depending on the project setup, using `mongoose = require('mongoose')` may point to a different instance of mongoose. To access the mongoose instance used by mongoose-wrangler:

```coffee
mongoose = require('mongoose-wrangler').mongoose
```

### Additional Connections

Mongoose Wrangler handles multiple-connections with a few extra steps:

1. Model files should export a function ```model(connection)``` which Mongoose Wrangler can call with the additional connection after it has been set up. i.e.:
  ```coffee
  exports.model = (connection) ->
    connection.model "user", schema
  ```
1. Recall the model for an additional connection using the connection's index in the ```additional``` array:

  ```coffee
  MongooseWrangler.additional[0].model("my-model")
  ```

### Express Streaming with GridFS

Take advantage of Node.js streaming with GridFS and Express.js. Requested files are streamed to client a chunk at a time instead of loading completely into memory.

```coffee
gridfs = require('mongoose-wrangler').gridfs

exports.getFile = (req, res) ->
  options =
    filename: req.params.filename

  # first check if file exists because createReadStream on non-existing file bombs hard
  gridfs.exist options, (err, found) ->
    handleError(res, err) if err
    if found
      # set up a read stream and pipe to express response for efficiency
      readstream = gridfs.createReadStream options
      readstream.pipe res
    else
      res.send 404
```

### Debug

Using the `debug: true` option will print out a little more information such as each model as it is loaded.

## Testing

```bash
$ npm test
```

## License

  [MIT](LICENSE)
