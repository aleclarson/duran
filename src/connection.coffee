{extend, set, uhoh} = require "./utils"
debug = require "debug"
net = require "net"


Connection = ->
  set this, "_state", 0
  set this, "_socket", null
  return this

extend Connection,

  write: (data) ->
    @_socket.write data
    return

  disconnect: ->
    @_socket.end() if @_socket
    return

  connect: (opts, parse, emit) ->
    @_state = 1
    return new Promise (resolve, reject) =>
      socket = net.createConnection
        host: opts.host
        port: opts.port

      socket.once "connect", =>
        @_state = 2

        # Wait for greeting.
        socket.once "data", (data) ->
          socket.on "data", parse
          emit "connect", data
          resolve()

      .once "close", =>
        connected = @_state > 1
        @_state = 0
        @_socket = null
        emit "close", connected

      .once "error", (err) ->
        emit "error", err
        reject err

      # Disable buffering on write.
      socket.setNoDelay true

      # Ping every 25 seconds.
      socket.setKeepAlive true, 25000

      @_socket = socket
      return

module.exports = Connection
