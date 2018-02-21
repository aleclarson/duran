// Generated by CoffeeScript 2.2.0
var Box, BoxSchema, Connection, Emitter, Request, RequestQueue, createParser, debug, events, extend, ip, retry, set, untuple;

({extend, set, untuple} = require("./utils"));

createParser = require("./response/parser");

RequestQueue = require("./request/queue");

Connection = require("./connection");

BoxSchema = require("./schema");

Request = require("./request");

Emitter = require("emitter");

retry = require("./retry");

debug = require("debug");

ip = require("./iproto");

events = ["connect", "disconnect", "error"];

// TODO: Retry pending requests if connection is lost.
Box = function(opts = {}) {
  set(this, "_conn", null);
  set(this, "_queue", new RequestQueue(opts.limit, this));
  set(this, "_parse", createParser(this._queue));
  set(this, "_schema", new BoxSchema(this));
  set(this, "_events", new Emitter(events));
  set(this, "_closing", Promise.resolve());
  set(this, "_timeout", opts.timeout || 20e3);
  this._events.on("connect", async() => {
    await this._schema.load();
    this._queue.resume();
  });
  this._events.on("disconnect", () => {
    this._queue.pause();
    this._queue.recover();
    this.user = null;
  });
  this.user = null;
  return this;
};

extend(Box, {
  login: function(opts) {
    if (this.host) {
      if (opts.host == null) {
        opts.host = this.host;
      }
    }
    if (this.port) {
      if (opts.port == null) {
        opts.port = this.port;
      }
    }
    if (this._conn) {
      this._disconnect();
    }
    this._connect(opts);
    return this;
  },
  connect: function(opts) {
    if (!this._conn) {
      this._connect(opts);
    }
    return this;
  },
  disconnect: function() {
    if (this._abort) {
      this._abort();
      this._abort = null;
    }
    if (this._conn) {
      this._disconnect();
    }
    return this;
  },
  on: function(evt, fn) {
    return this._events.on(evt, fn);
  },
  once: function(evt, fn) {
    return this._events.once(evt, fn);
  },
  call: function() {
    var req;
    this._queue.push(req = this._call(...arguments));
    return req.promise.then(untuple);
  },
  space: function(name) {
    return this._schema.getSpace(name);
  },
  _connect: async function(opts = {}) {
    var conn, emit;
    this._conn = conn = new Connection;
    // The connection listener
    emit = (evt, arg) => {
      if (evt === "close") {
        // Try reconnecting if
        if (conn === this._conn) {
          this._conn = null;
          this._abort || set(this, "_abort", retry(() => {
            this._conn = conn = new Connection;
            return this._conn.connect(opts, this._parse, emit);
          }));
        }
        if (arg) {
          // Emit "disconnect" event if we were connected.
          this._events.emit("disconnect");
        }
        return;
      }
      if (evt === "connect") {
        if (this._abort) {
          this._abort = null;
        }
        if (opts.user) {
          opts.salt = arg.slice(64, 108).toString();
          return this._auth(opts);
        } else {
          this.user = "guest";
        }
      }
      this._events.emit(evt, arg);
    };
    if (this._abort) {
      this._abort();
      this._abort = null;
    }
    this.host = opts.host != null ? opts.host : opts.host = "127.0.0.1";
    this.port = opts.port != null ? opts.port : opts.port = 3301;
    // Wait for the old socket to close before connecting.
    await this._closing;
    try {
      return (await conn.connect(opts, this._parse, emit));
    } catch (error) {}
  },
  _disconnect: function() {
    var conn;
    conn = this._conn;
    this._conn = null;
    return this._closing = new Promise(function(resolve) {
      conn._socket.once("close", resolve);
      return conn.disconnect();
    });
  },
  _auth: function(opts) {
    var req;
    req = new Request(ip.AUTH, opts);
    req.retry = false;
    this._queue._send(req);
    return req.promise.then(() => {
      this.user = opts.user;
      return this._events.emit("connect");
    }).catch((err) => {
      this._events.emit("error", err);
      this.user = null;
      return this.disconnect();
    });
  },
  _request: function(cmd, opts) {
    var req;
    this._queue.push(req = new Request(cmd, opts));
    return req.promise;
  },
  _call: function(func) {
    var args, i;
    i = 0;
    args = new Array(arguments.length - 1);
    while (++i < args.length) {
      args[i - 1] = arguments[i];
    }
    return new Request(ip.CALL, {func, args});
  },
  _send: function(req) {
    this._queue._send(req);
    return req.promise;
  }
});

module.exports = function(opts) {
  return new Box(opts);
};