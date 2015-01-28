if window?
  parser = require 'ccss-compiler'
else
  chai = require 'chai' unless chai
  parser = require '../lib/compiler'

twodunpack = parser.twoDimensionUnpack

{expect, assert} = chai

eql = (thing1, thing2) ->
  expect(JSON.parse(JSON.stringify(thing1))).to.eql JSON.parse(JSON.stringify(thing2))

twoDimensionsMappingTest = (name, input, output) ->
  describe name, ->
    it '// 2d-map', ->
      eql twodunpack(input), output
    it '// ignores', ->
      eql twodunpack(output), output

equivalent = () -> # ( "title", source0, source1, source2...)
  sources = [arguments...]
  title = sources.splice(0,1)[0]
  results = []
  describe title + " ok", ->
    it "sources ok ✓", ->
      for source, i in sources
        results.push JSON.parse JSON.stringify parser.parse source
        assert results[results.length-1].commands?, "source #{i} is ok"
  describe title, ->
    for source, i in sources
      if i isnt 0
        it "source #{i} == source #{i - 1}  ✓", ->
          expect(results[1]).to.eql results.splice(0,1)[0]


describe "twodunpacker", ->

  it 'existential', ->
    expect(twodunpack).to.exist

  # inline 2d mapping
  # ====================================================================

  describe "2D properties are well unpacked", ->

    twoDimensionsMappingTest 'when having a single inline constraint with 2d on the left',
        commands:
          [
            ['==', ['get', ['#', 'div'], 'size'], 100]
          ]
      ,
        commands:
          [
            ['==', ['get', ['#', 'div'], 'width'], 100]
            ['==', ['get', ['#', 'div'], 'height'], 100]
          ]

    twoDimensionsMappingTest 'when having a single inline constraint with 2d on the right',
        commands:
          [
            ['==', ['get', ['tag', 'div'], 'y'], ['get', ['tag', 'li'], 'size']]
          ]
      ,
        commands:
          [
            ['==', ['get', ['tag', 'div'], 'y'], ['get', ['tag', 'li'], 'width']]
            ['==', ['get', ['tag', 'div'], 'y'], ['get', ['tag', 'li'], 'height']]
          ]

    twoDimensionsMappingTest 'when constraining a variable against a 2d property',
        commands:
          [
            ['==', ['get', 'varx'], ['get', ['tag', 'li'], 'size']]
          ]
      ,
        commands:
          [
            ['==', ['get', 'varx'], ['get', ['tag', 'li'], 'width']]
            ['==', ['get', 'varx'], ['get', ['tag', 'li'], 'height']]
          ]

    twoDimensionsMappingTest 'when multiple 2d constraint present at the root level',
        commands:
          [
            ['==', ['get', 'varx'], ['get', ['tag', 'li'], 'size']]
            ['==', ['get', 'varx'], ['get', ['tag', 'li'], 'position']]
          ]
      ,
        commands:
          [
            ['==', ['get', 'varx'], ['get', ['tag', 'li'], 'width']]
            ['==', ['get', 'varx'], ['get', ['tag', 'li'], 'height']]
            ['==', ['get', 'varx'], ['get', ['tag', 'li'], 'x']]
            ['==', ['get', 'varx'], ['get', ['tag', 'li'], 'y']]
          ]

    twoDimensionsMappingTest 'when constraining a 2d property with a variable',
        commands:
          [
            ['==', ['get', ['tag', 'div'], 'size'], ['get', 'varx']]
          ]
      ,
        commands:
          [
            ['==', ['get', ['tag', 'div'], 'width'], ['get', 'varx']]
            ['==', ['get', ['tag', 'div'], 'height'], ['get', 'varx']]
          ]

    twoDimensionsMappingTest 'when having a 2d on both side of the constraint',
        commands:
          [
            ['==', ['get', ['tag', 'div'], 'size'], ['get', ['tag', 'li'], 'size']]
          ]
      ,
        commands:
          [
            ['==', ['get', ['tag', 'div'], 'width'], ['get', ['tag', 'li'], 'width']]
            ['==', ['get', ['tag', 'div'], 'height'], ['get', ['tag', 'li'], 'height']]
          ]

    twoDimensionsMappingTest 'when having a single inline constraint with arithmetic operation',
        commands:
          [
            ['/', ['==', ['get', ['#', 'div'], 'size'], 100], 2]
          ]
      ,
        commands:
          [
            ['/', ['==', ['get', ['#', 'div'], 'width'], 100], 2]
            ['/', ['==', ['get', ['#', 'div'], 'height'], 100], 2]
          ]

    twoDimensionsMappingTest 'when having a single inline constraint with arithmetic operation on both side',
        commands:
          [
            ['==', ['/', ['get', ['tag', 'div'], 'size'], 2], ['/', ['get', ['tag', 'li'], 'size'], 2]]
          ]
      ,
        commands:
          [
            ['==', ['/', ['get', ['tag', 'div'], 'width'], 2], ['/', ['get', ['tag', 'li'], 'width'], 2]]
            ['==', ['/', ['get', ['tag', 'div'], 'height'], 2], ['/', ['get', ['tag', 'li'], 'height'], 2]]
          ]


    twoDimensionsMappingTest 'when having a 2D constraint within a ruleset',
        commands:
          [
            ['rule', ['.', 'className'],
            	[
            		['==', ['get', ['&'], 'width'], ['get', ['#', 'some'], 'size']]
            	]
            ]
          ]
      ,
        commands:
          [
            ['rule', ['.', 'className'],
            	[
            		['==', ['get', ['&'], 'width'], ['get', ['#', 'some'], 'width']]
                ['==', ['get', ['&'], 'width'], ['get', ['#', 'some'], 'height']]
            	]
            ]
          ]

      twoDimensionsMappingTest 'when 2D properties contained in nesting rulesets',
          commands:
            [
              ['rule', ['.', 'className'],
              	[
              		['==', ['get', ['&'], 'width'], ['get', ['#', 'some'], 'size']]
                  ['rule', ['.', 'className'],
                  	[
                  		['==', ['get', ['&'], 'width'], ['get', ['#', 'some'], 'size']]
                  	]
                  ]
              	]
              ]
            ]
        ,
          commands:
            [
              ['rule', ['.', 'className'],
              	[
              		['==', ['get', ['&'], 'width'], ['get', ['#', 'some'], 'width']]
                  ['==', ['get', ['&'], 'width'], ['get', ['#', 'some'], 'height']]
                  ['rule', ['.', 'className'],
                  	[
                  		['==', ['get', ['&'], 'width'], ['get', ['#', 'some'], 'width']]
                      ['==', ['get', ['&'], 'width'], ['get', ['#', 'some'], 'height']]
                  	]
                  ]
              	]
              ]
            ]

        twoDimensionsMappingTest 'when having 2d constraints in nested rulesets',
            commands:
              [
                ['rule', ['.', 'className'],
                	[
                		['==', ['get', ['&'], 'width'], ['get', ['#', 'some'], 'size']]
                    ['rule', ['.', 'className'],
                    	[
                    		['==', ['get', ['&'], 'width'], ['get', ['#', 'some'], 'size']]
                    	]
                    ]
                	]
                ]
              ]
          ,
            commands:
              [
                ['rule', ['.', 'className'],
                	[
                		['==', ['get', ['&'], 'width'], ['get', ['#', 'some'], 'width']]
                    ['==', ['get', ['&'], 'width'], ['get', ['#', 'some'], 'height']]
                    ['rule', ['.', 'className'],
                    	[
                    		['==', ['get', ['&'], 'width'], ['get', ['#', 'some'], 'width']]
                        ['==', ['get', ['&'], 'width'], ['get', ['#', 'some'], 'height']]
                    	]
                    ]
                	]
                ]
              ]

        twoDimensionsMappingTest 'when having 2d constraints in a virtual',
            commands:
              [
                ['rule', ['virtual', 'area'],
                	[
                		['==', ['get', ['&'], 'size'], ['get', ['.', 'className'], 'size']]
                	]
                ]
              ]
          ,
            commands:
              [
                ['rule', ['virtual', 'area'],
                	[
                		['==', ['get', ['&'], 'width'], ['get', ['.', 'className'], 'width']]
                    ['==', ['get', ['&'], 'height'], ['get', ['.', 'className'], 'height']]
                	]
                ]
              ]

        twoDimensionsMappingTest 'when having in a virtual a constraint which is the sum of the division of two 2D constraints',
            commands:
              [
                ['rule', ['virtual', 'area'],
                	[
                		['==', ['get', ['&'], 'size'], ['+', ['/', ['get', ['.', 'className'], 'size'], 2], ['get', ['#', 'div'], 'size']]]
                	]
                ]
              ]
          ,
            commands:
              [
                ['rule', ['virtual', 'area'],
                	[
                		['==', ['get', ['&'], 'width'], ['+', ['/', ['get', ['.', 'className'], 'width'], 2], ['get', ['#', 'div'], 'width']]]
                    ['==', ['get', ['&'], 'height'], ['+', ['/', ['get', ['.', 'className'], 'height'], 2], ['get', ['#', 'div'], 'height']]]
                	]
                ]
              ]
