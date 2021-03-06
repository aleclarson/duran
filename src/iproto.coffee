
module.exports =

  # Key codes
  CODE: 0x00
  SYNC: 0x01
  SCHEMA_ID: 0x05
  SPACE_ID: 0x10
  INDEX_ID: 0x11
  LIMIT: 0x12
  OFFSET: 0x13
  ITERATOR: 0x14
  KEY: 0x20
  TUPLE: 0x21
  FUNCTION_NAME: 0x22
  USERNAME: 0x23
  EXPRESSION: 0x27
  OPS: 0x28

  # Command codes
  SELECT: 0x01
  INSERT: 0x02
  REPLACE: 0x03
  UPDATE: 0x04
  DELETE: 0x05
  AUTH: 0x07
  EVAL: 0x08
  UPSERT: 0x09
  CALL: 0x0a

  # Iterator types
  EQ: 0
  REQ: 1
  ALL: 2
  LT: 3
  LE: 4
  GE: 5
  GT: 6
  BITS_ALL_SET: 7
  BITS_ANY_SET: 8
  BITS_ALL_NOT_SET: 9
  OVERLAPS: 10
  NEIGHBOR: 11
