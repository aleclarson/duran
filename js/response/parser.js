// Generated by CoffeeScript 2.2.0
var createBuffer, createParser, debug, msgpack;

createBuffer = require("./buffer");

msgpack = require("msgpack-lite");

debug = require("debug");

createParser = function(queue) {
  var buf, decoder, len, parsing, resolve;
  // True when a response is being parsed
  parsing = false;
  // The response buffer
  buf = createBuffer();
  // The response length
  len = -1;
  // The response decoder
  decoder = new msgpack.Decoder();
  // Resolve a request with a slice of bytes.
  resolve = function(data, pos) {
    var id, ok, res;
    decoder.buffer = data;
    decoder.offset = pos + 23;
    res = decoder.fetch();
    decoder.buffer = null;
    id = data.readUInt32BE(pos + 13);
    ok = 0 === data.readUInt32BE(pos + 3);
    return queue.resolve(id, ok, res);
  };
  return function(data) {
    var body, end, pos;
    // This packet begins with a new response.
    if (!parsing) {
      // Something went wrong.
      if (data.length < 5) {
        console.warn("Received incomplete packet: " + data.toString("hex"));
        return;
      }
      pos = 0;
      end = 0;
      // Split the packet into separate responses as needed.
      while (true) {
        end += 5 + data.readUInt32BE(pos + 1);
        pos += 5;
        // This packet ended with an incomplete response body.
        if (end > data.length) {
          parsing = true;
          len = end - pos;
          break;
        }
        // The body of a response finished in this packet.
        if (end > pos) {
          resolve(data, pos);
          pos = end;
        }
        // Another response begins in this packet.
        if (pos < data.length) {
          // This packet ended with an incomplete response size.
          if (pos + 5 > data.length) {
            parsing = true;
            len = -1;
            break;
          }
        } else {
          return;
        }
      }
      // Buffer the unresolved data.
      // This packet ended with a complete response body.
      return buf.write(data, pos, data.length - pos);
    } else {
      // This packet continues an in-progress response.
      buf.write(data);
      // This packet begins with the response size.
      if (len < 0) {
        len = buf.size();
      }
      // Resolve any finished requests.
      while (body = buf.read()) {
        resolve(body, 0);
        // Continue to the next response.
        len = buf.size();
        if (len < 0) {
          break;
        }
      }
      // The next packet will begin with a new response.
      if (buf.is_empty()) {
        parsing = false;
      }
    }
  };
};

module.exports = createParser;
