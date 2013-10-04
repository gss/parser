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
      chai.expect(result.selectors).to.eql expect.selectors or []
      chai.expect(result.commands).to.eql expect.commands or []
      #chai.expect(result.measures).to.eql expect.measures or []
      #chai.expect(result.vars).to.eql expect.vars or []
      #chai.expect(result.constraints).to.eql expect.constraints or []

describe 'CCSS-to-AST', ->
  it 'should provide a parse method', ->
    chai.expect(parser.parse).to.be.a 'function'
  
  describe "/* Basics */", ->
  
    parse """
            10 <= 2 == 3 < 4 == 5 // chainning numbers, maybe should throw error?
          """
        , 
          {
            selectors: []
            commands: [
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
            selectors: ["#box2"]
            commands: [
              ['var', "[grid-height]", 'grid-height']
              ['var', '#box2[width]','width', ['$id', 'box2']]
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
  
  describe "/* Normalize Names */", ->
    
    parse """
            #b[left] == [left];
            [left-col] == [col-left];
          """
        ,
          {
            selectors: ['#b']
            commands: [
              ['var', '#b[x]','x', ['$id', 'b']]
              ['var', '[left]','left']
              ['eq', ['get', '#b[x]'], ['get', '[left]']]
              ['var', '[left-col]','left-col']
              ['var', '[col-left]','col-left']
              ['eq', ['get', '[left-col]'], ['get', '[col-left]']]
            ]
          }
    parse """
            #b[top] == [top];
          """
        ,
          {
            selectors: ['#b']
            commands: [
              ['var', '#b[y]','y', ['$id', 'b']]
              ['var', '[top]','top']
              ['eq', ['get', '#b[y]'], ['get', '[top]']]
            ]
          }
    ###
    parse """
            #b[cx] == [cx];
          """
        ,
          {
            selectors: ['#b']
            commands: [
              ['var', '#b[center-x]','center-x', ['$id', 'b']]
              ['var', '[cx]','cx']
              ['eq', ['get', '#b[center-x]'], ['get', '[cx]']]
            ]
          }
    parse """
            #b[cy] == [cy];
          """
        ,
          {
            selectors: ['#b']
            commands: [
              ['var', '#b[center-y]','center-y', ['$id', 'b']]
              ['var', '[cy]','cy']
              ['eq', ['get', '#b[center-y]'], ['get', '[cy]']]
            ]
          }
    ###
  
  describe "/* Strength */", ->
    
    parse """
            4 == 5 == 6 !strong10 // w/ strength and weight
          """
        ,
          {
            selectors: []
            commands: [
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
            commands: [
              ['var', '#box[width]', 'width', ['$id', 'box']]
              ['var', '[grid-height]', 'grid-height']
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
            commands: [
              ['var', '#box[width]', 'width', ['$id', 'box']]
              ['var', '[grid-height]', 'grid-height']
              ['stay', ['get', '#box[width]'], ['get', '[grid-height]']]
            ]
          }
  
  describe "/* Variable Expressions */", ->
    
    parse """
            #box[right] == #box2[x];
          """
        ,
          {
            selectors: [
              '#box'
              '#box2'
            ]
            commands: [
              ['var', '#box[x]', 'x', ['$id','box']]
              ['var', '#box[width]', 'width', ['$id', 'box']]
              ['varexp', '#box[right]', ['plus',['get','#box[x]'],['get','#box[width]']], ['$id','box']]
              ['var', '#box2[x]', 'x', ['$id','box2']]
              ['eq', ['get','#box[right]'],['get','#box2[x]']]
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
            commands: [
              ['var', '::this[width]', 'width', ['$reserved', 'this']]
              ['var', '::document[width]', 'width', ['$reserved', 'document']]
              ['var', '::viewport[width]', 'width', ['$reserved', 'viewport']]
              ['eq', ['get', '::this[width]'], ['get', '::document[width]']]
              ['eq', ['get', '::document[width]'], ['get', '::viewport[width]']]
            ]
          }

  describe '/ Intrinsic Props & dedups /', ->
    # should do nothing special...
    parse """
            #box[width] == #box[intrinsic-width]; 
            [grid-col-width] == #box[intrinsic-width];
          """
        ,
          {
            selectors: [
              '#box'
            ]
            commands: [
              ['var', '#box[width]', 'width', ['$id', 'box']]
              ['var', '#box[intrinsic-width]', 'intrinsic-width', ['$id', 'box']]              
              ['eq', ['get', '#box[width]'], ['get', '#box[intrinsic-width]']]
              ['var', '[grid-col-width]', 'grid-col-width']
              ['eq', ['get', '[grid-col-width]'], ['get', '#box[intrinsic-width]']]
            ]
          }
    parse """
            #box[right] == #box[intrinsic-right]; 
          """
        ,
          {
            selectors: [
              '#box'
            ]
            commands: [
              ['var', '#box[x]', 'x', ['$id','box']]
              ['var', '#box[width]', 'width', ['$id', 'box']]
              ['varexp', '#box[right]', ['plus',['get','#box[x]'],['get','#box[width]']], ['$id','box']]              
              ['var', '#box[intrinsic-right]', 'intrinsic-right', ['$id', 'box']]              
              ['eq', ['get', '#box[right]'], ['get', '#box[intrinsic-right]']]
            ]
          }

  # This should probably be handled with a preparser or optimizer, not the main PEG grammar
  #
  #describe '/* 2D */', ->
  #
  #  parse """
  #          @-gss-stay #box[size];
  #          #box[position] >= measure(#box[position]) !require;
  #          // with a 2D stay, 2D constraint and measure    
  #        """
  #      ,
  #        {
  #          selectors: [
  #            '#box'
  #          ]
  #          vars: [
  #            ['get', '#box[width]', 'width', ['$id', 'box']]
  #            ['get', '#box[height]', 'height', ['$id', 'box']]
  #            ['get', '#box[x]', 'x', ['$id', 'box']]
  #            ['get', '#box[y]', 'y', ['$id', 'box']]
  #          ]
  #          constraints: [
  #            ['stay', ['get', '#box[width]']]
  #            ['stay', ['get', '#box[height]']]
  #            ['gte', ['get', '#box[x]'], ['measure', ['get', '#box[x]']], 'require']
  #            ['gte', ['get', '#box[y]'], ['measure', ['get', '#box[y]']], 'require']
  #          ]
  #        }