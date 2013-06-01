if typeof process is 'object' and process.title is 'node'
  chai = require 'chai' unless chai
  parser = require '../lib/ccss-compiler'
else
  parser = require 'ccss-compiler'

describe 'CCSS compiler', ->
  it 'should provide a parse method', ->
    chai.expect(parser.parse).to.be.a 'function'
    
  describe 'with multiple number statements', ->
    source = """
    10 <= 2 == 3 < 4 == 5
    """
    expect =
      selectors: [],
      vars: [],
      constraints: [
        ['lte', ['number', 10], ['number', 2]]
        ['eq', ['number', 2], ['number', 3]]
        ['lt', ['number', 3], ['number', 4]]
        ['eq', ['number', 4], ['number', 5]]
      ]
    result = null
    it 'should be able to produce a result', ->
      result = parser.parse source
      chai.expect(result).to.be.an 'object'
    it 'the result should match the expectation', ->
      chai.expect(result).to.eql expect

  describe 'with multiple statements containing variables and getters', ->
    source = """
    [grid-height] * #box2[width] <= 2 == 3 < 4 == 5
    """
    expect =
      selectors: [
        '#box2'
      ],
      vars: [
        ['get', 'grid-height']
        ['get', 'width', ['$', '#box2']]
      ],
      constraints: [
        ['lte', [
          'multiply', ['get', 'grid-height'], ['get', 'width', [
            '$', '#box2'
          ]]
        ], ['number', 2]]
        ['eq', ['number', 2], ['number', 3]]
        ['lt', ['number', 3], ['number', 4]]
        ['eq', ['number', 4], ['number', 5]]
      ]
    result = null
    it 'should be able to produce a result', ->
      result = parser.parse source
      chai.expect(result).to.be.an 'object'
    it 'the result should match the expectation', ->
      chai.expect(result).to.eql expect

  describe 'with a simple statement and a constraint strength', ->
    source = """
    4 == 5 !strong:10
    """
    expect =
      selectors: []
      vars: []
      constraints: [
        ['eq', ['number', 4], ['number', 5], 'strong', 10]
      ]
    result = null
    it 'should be able to produce a result', ->
      result = parser.parse source
      chai.expect(result).to.be.an 'object'
    it 'the result should match the expectation', ->
      chai.expect(result).to.eql expect

  describe 'with a stay rule', ->
    source = """
    @-gss-stay #box[width], [grid-height];
    """
    expect =
      selectors: [
        '#box'
      ]
      vars: [
        ['get', 'width', [
          '$', '#box']]
        ['get', 'grid-height']
      ]
      constraints: [
        ['stay', ['get', 'width', [
          '$', '#box']
        ], ['get', 'grid-height']]
      ]
    result = null
    it 'should be able to produce a result', ->
      result = parser.parse source
      chai.expect(result).to.be.an 'object'
    it 'the result should match the expectation', ->
      chai.expect(result).to.eql expect
