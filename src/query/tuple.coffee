{extend, set, unimpl} = require "../utils"

Tuple = (space) ->
  @space = space
  set this, "_trace", Error()
  return this

extend Tuple,

  update: unimpl "Tuple#update"

  replace: unimpl "Tuple#replace"

  delete: unimpl "Tuple#delete"

module.exports = Tuple
