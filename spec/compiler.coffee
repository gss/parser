if typeof process is 'object' and process.title is 'node'
  chai = require 'chai' unless chai
  parser = require '../lib/ccss-compiler'
else
  parser = require 'ccss-compiler'

parse = (source, expect) ->
  result = null
  describe source, ->
    it 'should do something', ->
      result = parser.parse source
      chai.expect(result).to.be.an 'object'
    it 'should match expected', ->
      chai.expect(result).to.eql expect

describe 'CCSS-to-AST', ->
  it 'should provide a parse method', ->
    chai.expect(parser.parse).to.be.a 'function'
  
  describe "/* Basics */", ->
  
    parse """
            10 <= 2 == 3 < 4 == 5 // chainning numbers, maybe should throw error?
          """
        , 
          {
            selectors: [],
            vars: [],
            constraints: [
              ['lte', ['number', 10], ['number', 2]]
              ['eq', ['number', 2], ['number', 3]]
              ['lt', ['number', 3], ['number', 4]]
              ['eq', ['number', 4], ['number', 5]]
            ]
          }
            
    parse """
            [grid-height] * #box2[width] <= 2 == 3 < 4 == 5 // w/ multiple statements containing variables and getters
          """
        ,
          {
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
          }
  
  describe "/* Strength */", ->
    
    parse """
            4 == 5 == 6 !strong:10 // w/ strength and weight
          """
        ,
          {
            selectors: []
            vars: []
            constraints: [
              ['eq', ['number', 4], ['number', 5], 'strong', 10]
              ['eq', ['number', 5], ['number', 6], 'strong', 10]
            ]
          }
          
  describe "/* Stays */", ->
    
    parse """
            @-gss-stay #box[width], [grid-height];
          """
        ,
          {
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
          }
      
  describe '/* Reserved Pseudos */', ->
    
    parse """
            ::this[right] == ::document[right] == ::viewport[right]
          """
        ,
          {
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
          }
  
  describe '/* 2D */', ->
  
  describe '/ with a 2D stay, 2D constraint and measure', ->
    parse """
            @-gss-stay #box[size];
            #box[position] >= measure(#box[position]) !require;
            // with a 2D stay, 2D constraint and measure    
          """
        ,
          {
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
          }