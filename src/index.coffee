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


    # Find and load all mongoose models in the provided path
    if fs.existsSync @options.modelPath
      fs.readdirSync(@options.modelPath).forEach (file) =>
        if file.match /\.js|coffee$/
          console.log "Loading mongoose model: #{file}" if @options.debug
          require path.join(@options.modelPath, file)
    else
      console.log "No mongoose models found in #{@options.modelPath}" if @options.debug

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

  setTimeout ->
    x.disconnect()
  , 5000

do main if require.main is module
