msgpack = require "msgpack-lite"
crypto = require "crypto"
ip = require "../iproto"

algo = msgpack.encode "chap-sha1"

module.exports = (opts) ->
  user = msgpack.encode opts.user
  buf = @alloc 44 + user.length

  # map with 2 pairs
  buf[i = 14] = 0x82

  # username : string
  buf[++i] = ip.USERNAME
  user.copy buf, ++i
  i += user.length

  # array of 2 values
  buf[i] = ip.TUPLE
  buf[++i] = 0x92

  # password algorithm
  algo.copy buf, ++i
  i += algo.length

  # password : string(20)
  buf[i] = 0xb4
  pass = scramble opts.password or "", opts.salt
  pass.copy buf, ++i
  return

sha1 = (val) ->
  crypto.createHash("sha1").update(val).digest()

xor = (a, b) ->
  i = -1
  len = Math.max a.length, b.length
  buf = Buffer.allocUnsafe len
  buf[i] = a[i] ^ b[i] while ++i < len
  buf

scramble = (pass, salt) ->
  salt = new Buffer salt, "base64"
  pass = sha1 pass
  xor pass, sha1 Buffer.concat [
    salt.slice(0, 20)
    sha1 pass
  ]
