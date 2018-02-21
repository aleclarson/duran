utils = exports

utils.alias = (ctr, aliases) ->
  for name, alias of aliases
    ctr::[alias] = ctr::[name]
  return

utils.extend = (ctr, proto) ->
  for key, value of proto
    ctr::[key] = value
  return

utils.has = Function.call.bind(Object.hasOwnProperty)

utils.mapFn = (fn) ->
  if fn then (vals) -> vals.map fn

utils.set = (obj, key, value) ->
  Object.defineProperty obj, key, {value, writable: true}

utils.uhoh = (msg, code) ->
  e = Error msg
  e.code = code if code
  Error.captureStackTrace e, utils.uhoh
  throw e

utils.unimpl = (key) ->
  return -> throw Error "'#{key}' is not implemented yet"

utils.untuple = (tuple) ->
  if tuple.length > 1
  then tuple
  else tuple[0]

utils.wait = (ms, fn) ->
  setTimeout fn, ms

utils.withFormat = (format) ->
  if format then (tuple) ->
    res = {}
    for val, i in tuple
      res[format[i].name] = val
    return res
