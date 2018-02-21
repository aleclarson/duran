createBuffer = require "./buffer"
msgpack = require "msgpack-lite"
debug = require "debug"


createParser = (queue) ->

  # True when a response is being parsed
  parsing = false

  # The response buffer
  buf = createBuffer()

  # The response length
  len = -1

  # The response decoder
  decoder = new msgpack.Decoder()

  # Resolve a request with a slice of bytes.
  resolve = (data, pos) ->
    decoder.buffer = data
    decoder.offset = pos + 23
    res = decoder.fetch()
    decoder.buffer = null

    id = data.readUInt32BE pos + 13
    ok = 0 == data.readUInt32BE pos + 3
    queue.resolve id, ok, res

  return (data) ->

    # This packet begins with a new response.
    unless parsing

      # Something went wrong.
      if data.length < 5
        console.warn "Received incomplete packet: " + data.toString "hex"
        return

      pos = 0
      end = 0

      # Split the packet into separate responses as needed.
      while true
        end += 5 + data.readUInt32BE pos + 1
        pos += 5

        # This packet ended with an incomplete response body.
        if end > data.length
          parsing = true
          len = end - pos
          break

        # The body of a response finished in this packet.
        if end > pos
          resolve data, pos
          pos = end

        # Another response begins in this packet.
        if pos < data.length

          # This packet ended with an incomplete response size.
          if pos + 5 > data.length
            parsing = true
            len = -1
            break

        # This packet ended with a complete response body.
        else return

      # Buffer the unresolved data.
      buf.write data, pos, data.length - pos

    # This packet continues an in-progress response.
    else
      buf.write data

      # This packet begins with the response size.
      if len < 0
        len = buf.size()

      # Resolve any finished requests.
      while body = buf.read()
        resolve body, 0

        # Continue to the next response.
        len = buf.size()
        break if len < 0

      # The next packet will begin with a new response.
      if buf.is_empty()
        parsing = false
        return

module.exports = createParser
