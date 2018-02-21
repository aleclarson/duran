msgpack = require "msgpack-lite"
ip = require "../iproto"

module.exports = (opts) ->
  key = msgpack.encode opts.key
  buf = @alloc 31 + key.length

  # map with 6 pairs
  buf[i = 14] = 0x86

  # space_id : uint16
  buf[++i] = ip.SPACE_ID
  buf[++i] = 0xcd
  buf.writeUInt16BE opts.space, ++i
  i += 2

  # index_id : uint8
  buf[i] = ip.INDEX_ID
  buf[++i] = opts.index

  # limit : uint32
  buf[++i] = ip.LIMIT
  buf[++i] = 0xce
  buf.writeUInt32BE opts.limit, ++i
  i += 4

  # offset : uint32
  buf[i] = ip.OFFSET
  buf[++i] = 0xce
  buf.writeUInt32BE opts.offset, ++i
  i += 4

  # iterator : uint8
  buf[i] = ip.ITERATOR
  buf[++i] = opts.iter

  # key : mixed
  buf[++i] = ip.KEY
  key.copy buf, ++i
  return
