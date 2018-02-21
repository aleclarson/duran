# duran v0.0.2

NodeJS client driver for Tarantool 1.7+

**Why should I choose duran?** Utilizing the power of Tarantool functions,
the `duran` client driver provides features not available in other drivers,
like space management or index management. Not to mention a unique API with
powerful query building.

You must install [duran-lua](https://github.com/aleclarson/duran-lua) to use this library.

```lua
-- In your Lua application:
require "duran"
```

## Usage

The API is currently in alpha, with many features missing.

```js
const duran = require('duran')

// The `box` object connects to a Tarantool server.
const box = duran({
  limit: 100,         // max number of concurrent requests
  timeout: 30 * 1000, // request timeout (defaults to 20 seconds)
})

// Providing `user` and `password` is optional.
// The default user is "guest".
box.connect({
  host: '127.0.0.1', // the default
  port: 3301,        // the default
  user: 'admin',
  password: 'bacon',
  timeout: 5000,     // auth timeout (defaults to 0)
})

// The current username, which equals null until connected.
box.user

// The current host and port.
box.host
box.port

// Login as another user (even after connecting).
box.login({
  user: 'bobby',
  password: 'shrimp',
  host: '127.0.0.1',  // defaults to `box.host` or 127.0.0.1
  port: 3301,         // defaults to `box.port` or 3301
})

// Sever the connection. Unfinished requests will be resent upon reconnection.
box.disconnect()

// Listen for events with the `once` and `on` methods.
box.once('connect', () => console.log('connected!'))
```

Available events:
- `connect`
- `disconnect`
- `error`

The "connect" event occurs *after* the user is authenticated.

Requests made before the "connect" event are placed in a queue that will be
processed upon successful connection.

When a "disconnect" event occurs and requests exist that were sent but not resolved,
those requests will be resent upon reconnection. There is an exception to that rule;
write queries will throw an error if a disconnect occurs before they resolve.

After a "disconnect" event, attempts will be made to reconnect. After each failed
attempt, the delay is increased exponentially, up to 2 minutes between attempts.

### box.call(func, ...args)

Calling a stored procedure is simple! The returned promise resolves into a tuple.
If the tuple has a length of 1 or 0, its first value is returned instead of the tuple.

```js
let info = await box.call('box.schema.user.info')
```

### box.space(name)

Get a `Space` object. The returned space may not exist on the Tarantool server.
The `box.space` method is pure, which means the returned space is always the same object.

### space.create(opts)

Create the space on the Tarantool server. The user must be privileged.

The available options can be found [here](https://tarantool.org/en/doc/1.7/book/box/box_schema.html#box-schema-space-create).

You cannot call any other methods on the space until the returned promise is
resolved, because you will need the space ID from the Tarantool server.

```js
await box.space('test').create({
  temporary: true,
  if_not_exists: true,
})
```

### space.rename(name)

Rename the space. The user must be privileged.

You should not call `box.space(old_name)` until the returned promise is resolved.
Otherwise, you'll get the renamed space, because the schema is not updated until
the promise resolves without error.

Similarly, you should not call `box.space(new_name)` until the returned promise
is resolved. Otherwise, you'll get a new `Space` object that will be overwritten
by the renamed space.

```js
let space = box.space('test')
let promise = space.rename('foo')

box.space('foo') == space // => false
box.space('test') == space // => true

await promise

box.space('foo') == space // => true
box.space('test') == space // => false
```

### space.format(shape)

Impose strict types on tuple fields. The user must be privileged.

Documentation can be found [here](https://tarantool.org/en/doc/1.7/book/box/box_space.html#box-space-format).

```js
box.space('test').format([
  {name: 'id', type: 'unsigned'},
  {name: 'first_name', type: 'string'},
  {name: 'last_name', type: 'string'},
])
```

### space.truncate()

Delete all tuples in the space. The user must have created the space.

The `empty` method is identical.

### space.drop()

Destroy the space (and all tuples contained within). The user must be privileged.

If you intend to create a space with the same name immediately after, you must
wait for the returned promise to resolve before calling `space.create`.

```js
// Recreate the "test" space.
await box.space('test').drop()
await box.space('test').create()
```

### space.createIndex(name, opts)

Create an index for the space. The user must be privileged.

```js
box.space('test').createIndex('primary', {
  unique: true,
  if_not_exists: true,
  parts: [
    [1, 'unsigned'],
    [2, 'string', {is_nullable: true}],
  ]
})
```

Documentation can be found [here](https://tarantool.org/en/doc/1.7/book/box/box_space.html#lua-function.space_object.create_index).

In the future, the `parts` option will be made more user-friendly.

### space.renameIndex(name, new_name)

Rename an index of the space. The user must be privileged.

### space.alterIndex(name, opts)

Alter the structure of an index. The user must be privileged.

The `opts` object is identical to the `space.createIndex` options.

### space.dropIndex(name)

Destroy an index of the space. The user must be privileged.

You should not create an index with the same name *until* the returned
promise is resolved. Otherwise, an error will be thrown, because the
local schema is not yet updated.

&nbsp;

## Queries

The `run`, `then`, and `catch` methods exist on all query-like objects.

```js
// Get all tuples in a space.
let tuples = await space.run()

// Attach callbacks and trigger an implicit `run`.
let promise = space.then(tuples => {}, (err) => {})
promise = space.catch(err => {})
```

**NOTE:** Most query features are not implemented in this version.

### space.asc(index_name)

Sort all tuples in ascending order using an index.

```js
let tuples = await space.asc('name').run()
```

### space.desc(index_name)

Sort all tuples in descending order using an index.

```js
let tuples = await space.desc('name').run()
```

Omit the `index_name` argument to use the primary index.

```js
let tuples = await space.desc().run()
```

---

*More documentation coming soon...*
