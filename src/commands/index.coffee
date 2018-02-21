ip = require "../iproto"

AUTH = require "./auth"
CALL = require "./call"
SELECT = require "./select"

exports.get = (cmd) ->
  switch cmd
    when ip.AUTH then AUTH
    when ip.CALL then CALL
    when ip.SELECT then SELECT
    else throw badCommand cmd

badCommand = (cmd) ->
  Error "Unknown command: 0x" + (Buffer.from [cmd]).toString "hex"
