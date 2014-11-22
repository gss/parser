if window?
  parser = require 'ccss-compiler'
else
  chai = require 'chai' unless chai
  parser = require '../lib/compiler'
  
scope = parser.scope

{expect, assert} = chai
  
describe "Scoper", ->
  
  describe "var hoisting", ->
    
    it 'hoist 1 level root before', ->
    
      ast =
        commands:
          [
            ['==',['get','foo'],100]
            ['rule',['.','box'],
              [
                ['==',['get','foo'],100]
              ]
            ]
          ]
    
      expect(scope(ast)).to.eql commands: 
        [
          ['==',['get','foo'],100]
          ['rule',['.','box'],
            [
              ['==',['get',['^'],'foo'],100]
            ]
          ]
        ]
  
  
    it 'hoist 1 level root after', ->
    
      ast =
        commands:
          [          
            ['rule',['.','box'],
              [
                ['==',['get','foo'],100]
              ]
            ]
            ['==',['get','foo'],100]
          ]
    
      expect(scope(ast)).to.eql commands: 
        [        
          ['rule',['.','box'],
            [
              ['==',['get',['^'],'foo'],100]
            ]
          ]
          ['==',['get','foo'],100]
        ]
  
    it 'hoist 2 level before', ->
    
      ast =
        commands:
          [
            ['==',['get','foo'],0]
            ['rule',['.','box'],
              [
                ['==',['get','foo'],1]
                ['rule',['.','box'],
                  [
                    ['==',['get','foo'],2]
                  ]
                ]
              ]
            ]          
          ]
    
      expect(scope(ast)).to.eql commands: 
        [
          ['==',['get','foo'],0]
          ['rule',['.','box'],
            [
              ['==',['get',['^'],'foo'],1]
              ['rule',['.','box'],
                [
                  ['==',['get',['^',2],'foo'],2]
                ]
              ]
            ]
          ]          
        ]
      
  
    it 'hoist 2 level root after', ->
    
      ast =
        commands:
          [          
            ['rule',['.','box'],
              [
                ['rule',['.','box'],
                  [
                    ['==',['get','foo'],2]
                  ]
                ]
                ['==',['get','foo'],1]
              ]
            ]
            ['==',['get','foo'],0]
          ]
    
      expect(scope(ast)).to.eql commands: 
        [        
          ['rule',['.','box'],
            [
              ['rule',['.','box'],
                [
                  ['==',['get',['^',2],'foo'],2]
                ]
              ]
              ['==',['get',['^'],'foo'],1]
            ]
          ]
          ['==',['get','foo'],0]
        ]
  
  
    it 'DONT already hoisted 2 level root after', ->
    
      ast =
        commands:
          [        
            ['rule',['.','box'],
              [
                ['rule',['.','box'],
                  [
                    ['==',['get',['^'],'foo'],2]
                  ]
                ]
                ['==',['get',['^',1000],'foo'],1]
              ]
            ]
            ['==',['get','foo'],0]
          ]
    
      expect(scope(ast)).to.eql commands: 
        [        
          ['rule',['.','box'],
            [
              ['rule',['.','box'],
                [
                  ['==',['get',['^'],'foo'],2]
                ]
              ]
              ['==',['get',['^',1000],'foo'],1]
            ]
          ]
          ['==',['get','foo'],0]
        ]
    
    
    it 'conditionals', ->    
    
      ast =
        commands:
          [
            ['==',['get','foo'],0]
            ['rule',['.','box'],
              [
                ['if',
                  ['get','x']
                  [
                    ['set', 'font-family', 'awesome']
                    ['==',['get','foo'],1]
                  ]
                  [
                    ['get','y']
                    [
                      ['==',['get','foo'],1]
                      ['set', 'font-family', 'awesomer']
                    ]
                  ]
                  [
                    ['==',['get','foo'],1]
                    [
                      ['set', 'font-family', 'awesomest']
                      ['rule',['.','box'],
                        [
                          ['==',['get','foo'],2]
                        ]
                      ]
                    ]
                  ]
                ]                                
              ]
            ]
          ]
  
      expect(scope(ast)).to.eql commands: 
        [
          ['==',['get','foo'],0]
          ['rule',['.','box'],
            [
              ['if',
                ['get','x']
                [
                  ['set', 'font-family', 'awesome']
                  ['==',['get',['^'],'foo'],1]
                ]
                [
                  ['get','y']
                  [
                    ['==',['get',['^'],'foo'],1]
                    ['set', 'font-family', 'awesomer']
                  ]
                ]
                [
                  ['==',['get',['^'],'foo'],1]
                  [
                    ['set', 'font-family', 'awesomest']
                    ['rule',['.','box'],
                      [
                        ['==',['get',['^',2],'foo'],2]
                      ]
                    ]
                  ]
                ]
              ]                                
            ]
          ]
        ]
      
      
    