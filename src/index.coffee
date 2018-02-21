{extend, set, untuple} = require "./utils"
createParser = require "./response/parser"
RequestQueue = require "./request/queue"
Connection = require "./connection"
BoxSchema = require "./schema"
Request = require "./request"
Emitter = require "emitter"
retry = require "./retry"
debug = require "debug"
ip = require "./iproto"

events = ["connect", "disconnect", "error"]

# TODO: Retry pending requests if connection is lost.
Box = (opts = {}) ->
  set this, "_conn", null
  set this, "_queue", new RequestQueue opts.limit, this
  set this, "_parse", createParser @_queue
  set this, "_schema", new BoxSchema this
  set this, "_events", new Emitter events
  set this, "_closing", Promise.resolve()
  set this, "_timeout", opts.timeout or 20e3

  @_events.on "connect", =>
    await @_schema.load()
    @_queue.resume()
    return

  @_events.on "disconnect", =>
    @_queue.pause()
    @_queue.recover()
    @user = null
    return

  @user = null
  return this

extend Box,

  login: (opts) ->
    opts.host ?= @host if @host
    opts.port ?= @port if @port
    @_disconnect() if @_conn
    @_connect opts
    return this

  connect: (opts) ->
    @_connect opts unless @_conn
    return this

  disconnect: ->

    if @_abort
      @_abort()
      @_abort = null

    @_disconnect() if @_conn
    return this

  on: (evt, fn) ->
    @_events.on evt, fn

  once: (evt, fn) ->
    @_events.once evt, fn

  call: ->
    @_queue.push req = @_call ...arguments
    req.promise.then untuple

  space: (name) ->
    @_schema.getSpace name

  _connect: (opts = {}) ->
    @_conn = conn = new Connection

    # The connection listener
    emit = (evt, arg) =>

      if evt == "close"

        # Try reconnecting if
        if conn == @_conn
          @_conn = null
          @_abort or set this, "_abort", retry =>
            @_conn = conn = new Connection
            @_conn.connect opts, @_parse, emit

        # Emit "disconnect" event if we were connected.
        @_events.emit "disconnect" if arg
        return

      if evt == "connect"
        @_abort = null if @_abort
        if opts.user
          opts.salt = arg.slice(64, 108).toString()
          return @_auth opts
        else @user = "guest"

      @_events.emit evt, arg
      return

    if @_abort
      @_abort()
      @_abort = null

    @host = opts.host ?= "127.0.0.1"
    @port = opts.port ?= 3301

    # Wait for the old socket to close before connecting.
    await @_closing
    try await conn.connect opts, @_parse, emit

  _disconnect: ->
    conn = @_conn
    @_conn = null
    @_closing = new Promise (resolve) ->
      conn._socket.once "close", resolve
      conn.disconnect()

  _auth: (opts) ->
    req = new Request ip.AUTH, opts
    req.retry = false
    @_queue._send req

    req.promise.then =>
      @user = opts.user
      @_events.emit "connect"

    .catch (err) =>
      @_events.emit "error", err
      @user = null
      @disconnect()

  _request: (cmd, opts) ->
    @_queue.push req = new Request cmd, opts
    return req.promise

  _call: (func) ->
    i = 0
    args = new Array arguments.length - 1
    args[i - 1] = arguments[i] while ++i < args.length
    return new Request ip.CALL, {func, args}

  _send: (req) ->
    @_queue._send req
    return req.promise

module.exports = (opts) ->
  new Box opts
