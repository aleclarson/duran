{extend, mapFn, set, unimpl, withFormat} = require "../utils"
ip = require "../iproto"

MAX_UINT32 = 0xffffffff

Range = (space) ->
  @space = space
  set this, "_trace", Error()
  return this

extend Range,

  nth: unimpl "Range#nth"

  where: unimpl "Range#where"

  update: unimpl "Range#update"

  delete: unimpl "Range#delete"

  run: ->
    @space._box._request ip.SELECT,
      query: this
      transform: mapFn withFormat @space._format

  then: (resolveFn, rejectFn) ->
    @run().then resolveFn, rejectFn

  catch: (rejectFn) ->
    @run().catch rejectFn

  _build: ->
    {space, index} = this
    space._exists()

    if typeof index is "string"
      index = space._indexMap[index]

    space: space.id
    index: index or 0
    offset: @offset or 0
    limit: @limit or MAX_UINT32
    iter: @iter or ip.ALL
    key: @key or []

module.exports = Range
