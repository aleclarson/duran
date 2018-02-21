{extend, uhoh} = require "../utils"
commands = require "../commands"
noop = require "noop"
ip = require "../iproto"

MAX_UINT32 = 0xFFFFFFFF
nextId = 1

Request = (cmd, opts = {}) ->

  @id = nextId++
  nextId = 1 if nextId > MAX_UINT32

  # `cmd` or `opts.query.cmd` must exist before sending.
  @cmd = cmd or null

  if opts.query
  then @query = opts.query
  else @build cmd, opts

  # The response can be transformed.
  @transform = opts.transform or noop.arg1

  # Stalled requests can be rejected after some delay.
  if typeof opts.timeout is "number"
    @timeout = opts.timeout

  @promise = new Promise (resolve, reject) =>
    @resolve = resolve
    @reject = reject
    return

  return this

extend Request,

  alloc: (len) ->
    buf = Buffer.allocUnsafe len + 5
    buf[0] = 0xce
    buf.writeUInt32BE len, 1
    buf[5] = 0x82
    buf[6] = ip.CODE
    buf[7] = @cmd
    buf[8] = ip.SYNC
    buf[9] = 0xce
    buf.writeUInt32BE @id, 10
    return @buf = buf

  build: (cmd, opts) ->
    commands.get(cmd).call this, opts
    return

module.exports = Request
