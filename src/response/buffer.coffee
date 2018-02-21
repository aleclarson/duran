
# We must use a "sliding buffer" to parse responses:
#   - a response's size is consumed before its body
#   - many responses can exist in the buffer at any time
createBuffer = ->
  buf = Buffer.allocUnsafe 1024 * 10

  # The current position in the buffer
  pos = 0

  # How many bytes are currently used
  len = 0

  # The size of the next response body
  body_size = -1

  # Double the buffer size when necessary
  growth_factor = 2

  # Returns true if all responses have been consumed.
  is_empty: -> len == 0

  # Consume a response size.
  size: ->

    if body_size < 0 and len >= 5
      body_size = buf.readUInt32BE pos + 1
      pos += 5
      len -= 5

    return body_size

  # Consume a response body.
  read: ->

    if body_size < 0
      throw Error "Response body has unknown size"

    if len >= body_size
      res = buf.slice pos, body_size

      if res.length == len
        pos = 0
        len = 0
      else
        pos += body_size
        len -= body_size

      body_size = -1
      return res

  # Append data from their buffer into ours.
  write: (data, data_pos = 0, data_len = data.length) ->
    next_len = pos + len + data_len

    # Grow our buffer if necessary.
    if next_len > buf.length
      next_len = grow_until next_len, buf.length, growth_factor
      next_buf = Buffer.allocUnsafe next_len
      buf.copy next_buf, 0, pos, pos + len
      buf = next_buf
      pos = 0

    data.copy buf, pos + len, data_pos, data_pos + data_len
    len += data_len
    return

  reset: ->
    pos = 0
    len = 0
    body_size = -1
    return

module.exports = createBuffer

grow_until = (target_size, current_size, growth_factor) ->
  size = current_size
  while size < target_size
    size *= growth_factor
  return size
