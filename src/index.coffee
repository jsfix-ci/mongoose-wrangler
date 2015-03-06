fs = require 'fs'
path = require 'path'
{ EventEmitter } = require 'events'

mongoose = require 'mongoose'

#
# MongooseWrangler takes care of getting mongoose connected up to mongoDB and loading some
# mongoose models. It also takes care of registering some mongoose plugins.
#
class MongooseWrangler extends EventEmitter
  constructor: (@options={}) ->
    @connected = false

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

    # Connection open handler
    mongoose.connection.on 'open', =>
      console.log "Connected to mongoDB"
      @connected = true
      @emit 'connected'

    # Mongoose error handler
    mongoose.connection.on 'error', (err) =>
      console.log "mongoDB #{err}"
      @connected = false

    # Disconnected notice, let mongoose reconnect automatically
    mongoose.connection.on 'disconnected', =>
      @connected = false
      @emit 'disconnected'
      if @keepConnected
        console.log "Reconnecting to mongoDB"

    # Find and load all mongoose models in the provided path
    if fs.existsSync @options.modelPath
      fs.readdirSync(@options.modelPath).forEach (file) ->
        if file.match /\.js|coffee$/
          console.log "Loading mongoose model: #{file}" if @options.debug
          require path.join(@options.modelPath, file)

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
    console.log "Disconnecting mongoDB"
    mongoose.disconnect()

#
# Exports
#
module.exports = MongooseWrangler
