if typeof process is 'object' and process.title is 'node'
  chai = require 'chai' unless chai
  parser = require '../lib/ccss-compiler'
else
  parser = require 'ccss-compiler'

describe 'CCSS compiler', ->
  it 'should provide a parse method', ->
    chai.expect(parser.parse).to.be.a 'function'
