if window?
  parser = require 'ccss-compiler'
else
  chai = require 'chai' unless chai
  parser = require '../lib/compiler'

scope = parser.scope

{expect, assert} = chai

equivalent = () -> # ( "title", source0, source1, source2...)
  sources = [arguments...]
  title = sources.splice(0,1)[0]
  results = []
  describe title + " ok", ->
    it "sources ok ✓", ->
      for source, i in sources
        results.push parser.parse source
        assert results[results.length-1].commands?, "source #{i} is ok"
  describe title, ->
    for source, i in sources
      if i isnt 0
        it "source #{i} == source #{i - 1}  ✓", ->
          expect(results[1]).to.eql results.splice(0,1)[0]


describe "Scoper", ->


  # var hoisting raw commands
  # ====================================================================

  describe "var hoisting raw commands", ->

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


  # virtual hoisting raw commands
  # ====================================================================

  describe "virtual hoisting raw commands", ->

    it 'hoist 1 level root before', ->
      input =
        commands:
          [
            ['==',['get',['virtual','zone'],'foo'],100]
            ['rule',['.','box'],
              [
                ['==',['get',['virtual','zone'],'foo'],100]
              ]
            ]
          ]
      output =
        commands:
          [
            ['==',['get',['virtual','zone'],'foo'],100]
            ['rule',['.','box'],
              [
                ['==',['get',['virtual',['^'],'zone'],'foo'],100]
              ]
            ]
          ]
      expect(scope(input)).to.eql output
      expect(scope(output)).to.eql JSON.parse JSON.stringify output

    it 'hoist 1 level root after', ->
      ast =
        commands:
          [
            ['rule',['.','box'],
              [
                ['==',['get',['virtual','zone'],'foo'],100]
              ]
            ]
            ['==',['get',['virtual','zone'],'foo'],100]
          ]
      expect(scope(ast)).to.eql commands:
        [
          ['rule',['.','box'],
            [
              ['==',['get',['virtual',['^'],'zone'],'foo'],100]
            ]
          ]
          ['==',['get',['virtual','zone'],'foo'],100]
        ]


    it 'Dont hoist root', ->
      ast =
        commands:
          [
            ['==',['get',['virtual','zone'],'foo'],100]
          ]
      expect(scope(ast)).to.eql commands:
        [
          ['==',['get',['virtual','zone'],'foo'],100]
        ]

    it 'Dont consider ruleset selector child scope', ->
      ast =
        commands:
          [
            ['==',['get',['virtual','zone'],'foo'],100]
            ['rule', ['virtual','zone']
              [

              ]
            ]
          ]
      expect(scope(ast)).to.eql commands:
        [
          ['==',['get',['virtual','zone'],'foo'],100]
          ['rule', ['virtual','zone']
            [

            ]
          ]
        ]

    it '4 level', ->
      ast =
        commands:
          [
            ['rule', ['.','ready']
              [
                ['==',['get',['virtual','zone'],'foo'],100]
                ['rule', ['virtual','zone']
                  [
                    ['==',['get',['virtual',['.','box'],'zone'],'foo'],100]
                    ['rule', ['virtual','zone']
                      [
                        ['==',['get',['virtual',['.','box'],'zone'],'foo'],100]
                        ['rule', ['virtual','zone']
                          [
                            ['==',['get',['virtual','zone'],'foo'],100]
                          ]
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
          ['rule', ['.','ready']
            [
              ['==',['get',['virtual','zone'],'foo'],100]
              ['rule', ['virtual','zone']
                [
                  ['==',['get',['virtual',['.','box'],'zone'],'foo'],100]
                  ['rule', ['virtual',['^'],'zone']
                    [
                      ['==',['get',['virtual',['.','box'],'zone'],'foo'],100]
                      ['rule', ['virtual',['^',2],'zone']
                        [
                          ['==',['get',['virtual',['^',3],'zone'],'foo'],100]
                        ]
                      ]
                    ]
                  ]
                ]
              ]
            ]
          ]
        ]



  # manual & auto hoisting source equivalence
  # ====================================================================

  describe "manual & auto hoisting source equivalence", ->

    equivalent "1 level basic",
      """
        foo == bar;
        .box {
          foo == bar;
        }
      """,
      """
        foo == bar;
        .box {
          ^foo == ^bar;
        }
      """

    equivalent "3 level moderate",
      """

        @if foo > 20 {

        .outer {

          .box {
            20 * foo + 100 == bye - bar / 10;
            .inner {
              bye: == 50;
              20 * foo + 100 == bye - bar / 10;
            }
          }

          20 * foo + 100 == hey - bar / 10;

        }

        }

      """,
      """

        @if foo > 20 {

        .outer {

          .box {
            20 * ^^foo + 100 == bye - ^bar / 10;
            .inner {
              &bye == 50;
              20 * ^^^foo + 100 == ^bye - ^^bar / 10;
            }
          }

          20 * ^foo + 100 == hey - bar / 10;

        }

        }

      """



