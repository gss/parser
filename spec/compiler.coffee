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
        ['get', "[grid-height]", 'grid-height']
        ['get', '#box2[width]','width', ['$id', 'box2']]
      ],
      constraints: [
        ['lte', [
          'multiply', ['get', '[grid-height]'], ['get', '#box2[width]']
          ], 
          ['number', 2]
        ]
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

  describe 'with a simple statement and a constraint strength and weight', ->
    source = """
    4 == 5 == 6 !strong:10
    """
    expect =
      selectors: []
      vars: []
      constraints: [
        ['eq', ['number', 4], ['number', 5], 'strong', 10]
        ['eq', ['number', 5], ['number', 6], 'strong', 10]
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
        ['get', '#box[width]', 'width', ['$id', 'box']]
        ['get', '[grid-height]', 'grid-height']
      ]
      constraints: [
        ['stay', ['get', '#box[width]'], ['get', '[grid-height]']]
      ]
    result = null
    it 'should be able to produce a result', ->
      result = parser.parse source
      chai.expect(result).to.be.an 'object'
    it 'the result should match the expectation', ->
      chai.expect(result).to.eql expect
      
  describe ': with reserved pseudos', ->
    source = """
    ::this[right] == ::document[right] == ::viewport[right]
    """
    expect =
      selectors: [
        '::this'
        '::document'
        '::viewport'
      ]
      vars: [
        ['get', '::this[right]', 'right', ['$reserved', 'this']]
        ['get', '::document[right]', 'right', ['$reserved', 'document']]
        ['get', '::viewport[right]', 'right', ['$reserved', 'viewport']]
      ]
      constraints: [
        ['eq', ['get', '::this[right]'], ['get', '::document[right]']]
        ['eq', ['get', '::document[right]'], ['get', '::viewport[right]']]
      ]
    result = null
    it ': should be able to produce a result', ->
      result = parser.parse source
      chai.expect(result).to.be.an 'object'
    it ': the result should match the expectation', ->
      chai.expect(result).to.eql expect
  
  describe 'with a 2D stay, 2D constraint and measure', ->
    source = """
    @-gss-stay #box[size];
    #box[position] >= measure(#box[position]) !require;
    """
    expect =
      selectors: [
        '#box'
      ]
      vars: [
        ['get', '#box[width]', 'width', ['$id', '#box']]
        ['get', '#box[height]', 'height', ['$id', '#box']]
        ['get', '#box[x]', 'x', ['$id', '#box']]
        ['get', '#box[y]', 'y', ['$id', '#box']]
      ]
      constraints: [
        ['stay', ['get', '#box[width]']]
        ['stay', ['get', '#box[height]']]
        ['gte', ['get', '#box[x]'], ['measure', ['get', '#box[x]']], 'require']
        ['gte', ['get', '#box[y]'], ['measure', ['get', '#box[y]']], 'require']
      ]
    result = null
    it 'should be able to produce a result', ->
      result = parser.parse source
      chai.expect(result).to.be.an 'object'
    it 'the result should match the expectation', ->
      chai.expect(result).to.eql expect
