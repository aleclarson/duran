msgpack = require "msgpack-lite"
ip = require "../iproto"

module.exports = (opts) ->
  func = msgpack.encode opts.func
  args = msgpack.encode opts.args
  buf = @alloc 15 + func.length + args.length

  # map with 2 pairs
  buf[i = 14] = 0x82

  # function_name : string
  buf[++i] = ip.FUNCTION_NAME
  func.copy buf, ++i
  i += func.length

  # arguments : array
  buf[i] = ip.TUPLE
  args.copy buf, ++i
  return
