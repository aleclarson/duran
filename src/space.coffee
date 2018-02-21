{alias, extend, set, unimpl} = require "./utils"
isObject = require "is-object"
Range = require "./query/range"
Tuple = require "./query/tuple"

# TODO: Support custom field validation?
# TODO: Use the request queue for admin methods.
Space = (name, box) ->
  @id = null
  @name = name
  set this, "_box", box
  set this, "_format", null
  set this, "_indexMap", null
  set this, "_fieldCount", null
  return this

extend Space,

  create: (opts = {}) ->
    unless isObject opts
      throw TypeError "Expected an object"

    if @id isnt null
      throw Error "Space named '#{@name}' already exists"

    @id = await @_box.call "duran.space_create", @name, opts
    @_indexMap = {}
    @_fieldCount = 0

    return this

  rename: (name) ->
    if typeof name isnt "string"
      throw TypeError "Expected a string"

    @_exists()
    await @_box.call "duran.space_rename", @id, name

    @_box._schema.renameSpace @name, name
    @name = name
    return

  format: (format) ->
    unless Array.isArray format
      throw TypeError "Expected an array"

    @_exists()
    @_box.call "duran.space_format", @id, format

  truncate: ->
    @_exists()
    @_box.call "duran.space_truncate", @id

  drop: ->
    @_exists()
    await @_box.call "duran.space_drop", @id
    @_box._schema.deleteSpace @name

#
# Indexes
#

  createIndex: (name, opts) ->
    if typeof name isnt "string"
      throw TypeError "`name` must be a string"
    unless isObject opts
      throw TypeError "`opts` must be an object"

    @_exists()

    if @_indexMap[name]
      throw Error "Index named '#{@name}.#{name}' already exists"

    @_indexMap[name] =
      id: await @_box.call "duran.index_create", @id, name, opts
      unique: opts.unique isnt false
    return

  renameIndex: (name, new_name) ->
    if typeof name isnt "string"
      throw TypeError "`name` must be a string"
    if typeof new_name isnt "string"
      throw TypeError "`new_name` must be a string"

    @_exists()
    index = @_getIndex name
    await @_box.call "duran.index_rename", @id, name, new_name

    @_indexMap[new_name] = index
    delete @_indexMap[name]

  alterIndex: (name, opts) ->
    if typeof name isnt "string"
      throw TypeError "`name` must be a string"
    unless isObject opts
      throw TypeError "`opts` must be an object"

    @_exists()
    index = @_getIndex name
    @_box.call "duran.index_alter", @id, index.id

  dropIndex: (name) ->
    if typeof name isnt "string"
      throw TypeError "`name` must be a string"

    @_exists()
    index = @_getIndex name
    await @_box.call "duran.index_drop", @id, index.id

    delete @_indexMap[name]

#
# Queries
#

  get: (id) ->
    q = new Tuple this
    q.id = id
    q

  nth: unimpl "Space#nth"

  find: unimpl "Space#find"

  insert: unimpl "Space#insert"

  update: unimpl "Space#update"

  delete: unimpl "Space#delete"

  asc: (index) ->
    q = new Range this
    q.index = index or 0
    q.iter = ip.EQ
    q

  desc: (index) ->
    q = new Range this
    q.index = index or 0
    q.iter = ip.REQ
    q

  where: unimpl "Space#where"

  run: ->
    new Range(this).run()

  then: (resolveFn, rejectFn) ->
    new Range(this).then resolveFn, rejectFn

  catch: (rejectFn) ->
    new Range(this).catch rejectFn

#
# Internal
#

  _exists: ->
    if @id is null
      @_box._schema.deleteSpace @name
      throw Error "Unknown space: '#{@name}'"

  _getIndex: (name) ->
    return index if index = @_indexMap[name]
    throw Error "Unknown index: '#{@name}.#{name}'"

#
# Aliases
#

alias Space,
  empty: "truncate"

module.exports = Space
