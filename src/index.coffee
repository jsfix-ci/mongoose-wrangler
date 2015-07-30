# **Mongoose Wrangler** takes the guesswork out of managing a mongoose-powered connection to MongoDB.
# Mongoose provides auto-reconnect and other niceties, but there is still some setup involved.
# Wrangler attempts to automate as much as possible, including loading of mongoose model definition files.

fs = require 'fs'
path = require 'path'
{ EventEmitter } = require 'events'

# Mongoose is static, but only for the module instance which was loaded. Mongoose-wrangler will
# install it's own mongoose in `node_modules`, so user code must ask mongoose-wrangler for that
# instance. If user code does a `mongoose = require('mongoose')`, that var may point to a
# different mongoose.
mongoose = require 'mongoose'

#
# MongooseWrangler takes care of getting mongoose connected up to mongoDB and loading some
# mongoose models. It also takes care of registering some mongoose plugins.
#
class MongooseWrangler extends EventEmitter
  # Static property for accessing the mongoose wrangled by this module.
  @mongoose: mongoose
  # Static property for Long type provided by mongodb
  @Long: mongoose.mongo.Long
  # array for additional connections specified by the additional: option array
  @additional: []
  @Grid: require 'gridfs-stream'
  @gridfs: undefined

  constructor: (@options={}) ->
    # Flag signalling that we connected at least once. Mongoose's auto-reconnect only kicks in
    # once we've connected once.
    @hasConnected = false
    # Flag allowing us to differentiate between an intended disconnect and an accidental disconnect.
    @keepConnected = true

    # Options are provided using an options object at construction. These are the defaults.
    @options.debug ?= false
    @options.address ?= "127.0.0.1"
    @options.db ?= "test"
    @options.datatable ?= false
    @options.gridfs ?= false
    @options.modelPath ?= "./models"

    @configureMongoose()

  #
  # Configure Mongoose
  #
  configureMongoose: ->
    if @options.datatable
      @useDataTable()

    # Connect to mongoDB
    @connect()

    if @options.gridfs
      mongoose.connection.once 'open', =>
        @useGridFs()

    # Handle mongoose 'connected' event.
    mongoose.connection.on 'connected', =>
      console.log "mongoose-wrangler: Connected to mongoDB"
      @hasConnected = true
      @emit 'connected'

    # Handle mongoose 'error' event.
    mongoose.connection.on 'error', (err) =>
      console.log "mongoose-wrangler: mongoDB error: #{err}"

    # Disconnected notice, let mongoose reconnect automatically
    mongoose.connection.on 'disconnected', =>
      @emit 'disconnected'
      if not @hasConnected and @keepConnected
        console.log "mongoose-wrangler: Reconnecting to mongoDB"
        setTimeout =>
          @connect()
        , 1000

    # load models for main connection
    @loadModels @options.modelPath

  loadModels: (modelPath, conn) ->
    # Find and load all mongoose models in the provided path
    if fs.existsSync modelPath
      fs.readdirSync(modelPath).forEach (file) =>
        if file.match /\.js|coffee$/
          console.log "Loading mongoose model: #{file}" if @options.debug
          m = require path.join(modelPath, file)
          if m.model # mongoose-wrangler standard export for non-self-registering model
            if conn # if conn provided, use it, otherwise use base mongoose
              m.model conn
            else
              m.model mongoose
          else if conn
            console.log "WARNING: Connection was specified, but Model does not export model(connection) function"
    else
      console.log "No mongoose models found in #{modelPath}" if @options.debug

  #
  # Register the mongoose-datatable plugin
  #
  useDataTable: ->
    console.log "Registering mongoose-datatable plugin" if @options.debug
    DataTable = require 'mongoose-datatable'
    DataTable.configure
      verbose: false
      debug: false
    mongoose.plugin DataTable.init

  #
  # Set up gridfs-stream
  #
  useGridFs: ->
    console.log "Registering gridfs-stream plugin" if @options.debug
    MongooseWrangler.Grid.mongo = mongoose.mongo
    MongooseWrangler.gridfs = MongooseWrangler.Grid(mongoose.connection.db)

  #
  # Connect Mongoose to mongoDB
  #
  connect: ->
    @keepConnected = true
    uri = "mongodb://#{@options.address}/#{@options.db}"
    console.log "Connecting to mongoDB at #{uri}" if @options.debug
    options =
      server:
        auto_reconnect: true
        socketOptions:
          autoReconnect: true
          keepAlive: 1
    mongoose.connect uri, options

    if @options.additional
      for a in @options.additional
        uri = "mongodb://#{a.address}/#{a.db}"
        c = mongoose.createConnection uri, options
        c.on 'connected', ->
          console.log 'connected to additional'
        # Handle mongoose 'error' event.
        c.on 'error', (err) ->
          console.log "mongoose-wrangler: additional mongoDB error: #{err}"
        # load models for additional connection if present
        if a.modelPath
          @loadModels a.modelPath, c

        # add to array
        MongooseWrangler.additional.push c

  #
  # Manually disconnect from mongoDB
  #
  disconnect: ->
    @keepConnected = false
    console.log "mongoose-wrangler: Disconnecting from mongoDB"
    mongoose.disconnect()

#
# Exports
#
module.exports = MongooseWrangler

#
# Self-test
#
main = ->
  x = new MongooseWrangler
    debug: true

do main if require.main is module
