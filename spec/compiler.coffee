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
              ['var', "[grid-height]", 'grid-height']
              ['var', '#box2[width]','width', ['$id', 'box2']]
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
            4 == 5 == 6 !strong10 // w/ strength and weight
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
              ['var', '#box[width]', 'width', ['$id', 'box']]
              ['var', '[grid-height]', 'grid-height']
            ]
            constraints: [
              ['stay', ['get', '#box[width]'], ['get', '[grid-height]']]
            ]
          }
    parse """
            @stay #box[width], [grid-height];
          """
        ,
          {
            selectors: [
              '#box'
            ]
            vars: [
              ['var', '#box[width]', 'width', ['$id', 'box']]
              ['var', '[grid-height]', 'grid-height']
            ]
            constraints: [
              ['stay', ['get', '#box[width]'], ['get', '[grid-height]']]
            ]
          }
  
  describe "/* Variable Expressions */", ->
    
    parse """
            #box[right] == #box2[left];
          """
        ,
          {
            selectors: [
              '#box'
              '#box2'
            ]
            vars: [
              ['var', '#box[x]', 'x', ['$id','box']]
              ['var', '#box[width]', 'width', ['$id', 'box']]
              ['varexp', '#box[right]', ['plus',['get','#box[x]'],['get','#box[width]']]]
              ['var', '#box2[left]', 'left', ['$id','box2']]
            ]
            constraints: [
              ['eq', ['get','#box[right]'],['get','#box2[left]']]
            ]
          }
  
  describe '/* Reserved Pseudos */', ->
    
    parse """
            ::this[width] == ::document[width] == ::viewport[width]
          """
        ,
          {
            selectors: [
              '::this'
              '::document'
              '::viewport'
            ]
            vars: [
              ['var', '::this[width]', 'width', ['$reserved', 'this']]
              ['var', '::document[width]', 'width', ['$reserved', 'document']]
              ['var', '::viewport[width]', 'width', ['$reserved', 'viewport']]
            ]
            constraints: [
              ['eq', ['get', '::this[width]'], ['get', '::document[width]']]
              ['eq', ['get', '::document[width]'], ['get', '::viewport[width]']]
            ]
          }
  
  describe '/* Measures */', ->
    
    parse """
            #box[width] == measure(#box[width]);
          """
        ,
          {
            selectors: [
              '#box'
            ]
            measures: [
              # function,    varId,     prop,     selector
              ['measure', '#box[width]', 'width', ['$id', 'box']]
            ]              
            vars: [
              ['var', '#box[width]', 'width', ['$id', 'box']]
            ]           
            constraints: [
              ['eq', ['get', '#box[width]'], ['measure', ['get','#box[width]']] ]
            ]
          }
  
  describe '/* 2D */', ->
  
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
              ['get', '#box[width]', 'width', ['$id', 'box']]
              ['get', '#box[height]', 'height', ['$id', 'box']]
              ['get', '#box[x]', 'x', ['$id', 'box']]
              ['get', '#box[y]', 'y', ['$id', 'box']]
            ]
            constraints: [
              ['stay', ['get', '#box[width]']]
              ['stay', ['get', '#box[height]']]
              ['gte', ['get', '#box[x]'], ['measure', ['get', '#box[x]']], 'require']
              ['gte', ['get', '#box[y]'], ['measure', ['get', '#box[y]']], 'require']
            ]
          }