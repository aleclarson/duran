noop = require "noop"

resolved = Promise.resolve()
empty = {}

retry = (fn, opts = empty) ->
  tries = 0
  limit = opts.limit or Infinity
  exponent = opts.exponent or 2.2
  maxTimeout = 1000 * (opts.maxTimeout or 120)
  minTimeout = 1000 * (opts.minTimeout or 1)
  shouldRetry = opts.shouldRetry or noop.true

  cancelled = false
  run = ->
    unless cancelled
      resolved.then(fn).catch onError

  onError = (err) ->
    return if cancelled or tries == limit
    if shouldRetry err, tries
      timeout = getTimeout ++tries, exponent, minTimeout, maxTimeout
      timeout = setTimeout run, timeout
      return

  timeout = getTimeout ++tries, exponent, minTimeout, maxTimeout
  timeout = setTimeout run, timeout

  return ->
    cancelled = true
    clearTimeout timeout

module.exports = retry

getTimeout = (tries, exponent, minTimeout, maxTimeout) ->
  timeout = minTimeout

  # Use exponential backoff after the first 2 tries.
  if tries > 2
    timeout += 1000 * Math.pow exponent, tries - 2

    # Multiply by 0.75 - 1.25 to avoid "retry storms"
    timeout *= (0.75 + Math.random() / 2)

    # Apply the hard cap.
    return Math.min timeout, maxTimeout

  # Add up to 500ms to avoid "retry storms"
  return timeout + 500 * Math.random()
