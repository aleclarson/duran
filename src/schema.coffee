{extend, set, untuple} = require "./utils"
Space = require "./space"

BoxSchema = (box) ->
  set this, "_box", box
  set this, "_spaces", Object.create null
  return this

extend BoxSchema,

  getSpace: (name) ->
    unless space = @_spaces[name]
      @_spaces[name] = space = new Space name, @_box
    return space

  renameSpace: (old_name, new_name) ->
    if space = @_spaces[old_name]
      @_spaces[new_name] = space
      delete @_spaces[old_name]
    return false

  deleteSpace: (name) ->
    delete @_spaces[name]

  load: ->
    req = @_box._call "duran.spaces"
    req.retry = false

    spaces = await @_box._send(req).then untuple
    for name, data of spaces
      unless space = @_spaces[name]
        @_spaces[name] = space = new Space name, @_box
      space.id = data.id
      space._format = data.format
      space._fieldCount = data.field_count
      space._indexMap = data.index_map
    return

module.exports = BoxSchema
