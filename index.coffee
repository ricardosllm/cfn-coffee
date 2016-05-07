When = require 'when'
assert = require 'assert-plus'

module.exports = class

  constructor: (cfg) ->
    assert.object cfg, 'cfg'

    @s3 = new (require './s3')

  init: =>
    When.promise (resolve, reject) =>
      resolve @
