{extend, set, uhoh, wait} = require "../utils"
Denque = require "denque"
debug = require "debug"


# TODO: Avoid resending insert, update, and replace requests.
RequestQueue = (limit, box) ->
  @unsent = new Denque
  @limit = limit or null
  @sent = new Denque
  set this, "_box", box
  set this, "_paused", true
  return this

extend RequestQueue,

  # Add a request.
  push: (req) ->

    unless @_paused or @sent.size() == @limit
      return @_send req

    @unsent.push req
    return

  # Fulfill or reject a pending request.
  resolve: (id, ok, res) ->
    i = indexOf id, @sent
    req = @sent.removeOne i

    clearTimeout req._timeout

    if ok
    then req.resolve req.transform res[0x30]
    else req.reject Error res[0x31]

    if req = @_next()
      return @_send req

  # Pause flushing.
  pause: ->
    @_paused = true
    return

  # Resume flushing.
  resume: ->
    @_paused = false
    @_send req while req = @_next()
    return

  # Move all sent requests to the front of the unsent queue.
  recover: ->
    {sent, unsent} = this
    if count = sent.size()

      i = -1; while ++i < len
        req = sent.peekAt i
        clearTimeout req._timeout
        if req.retry isnt false
          unsent.unshift req

      sent.clear()
      return

  _next: ->
    unless @_paused or @sent.size() == @limit
      return @unsent.shift()

  _send: (req) ->
    {query, timeout} = req

    if query
      opts = query._build()
      req.build req.cmd or query.cmd, opts
      req.query = null

    conn = @_box._conn
    conn.write req.buf

    @sent.push req

    timeout ?= @_box._timeout
    if timeout > 0
      clearTimeout req._timeout
      req._timeout = wait timeout, =>
        req.reject uhoh "Request timed out", "ETIMEDOUT"
      return

module.exports = RequestQueue

# Find the index of a request.
indexOf = (id, queue) ->
  i = -1
  len = queue.size()
  while ++i < len
    req = queue.peekAt i
    return i if id == req.id
  return -1
