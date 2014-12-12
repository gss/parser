if window?
  parser = require 'ccss-compiler'
else
  chai = require 'chai' unless chai
  parser = require '../lib/compiler'

scope = parser.scope

{expect, assert} = chai

eql = (thing1, thing2) ->
  expect(JSON.parse(JSON.stringify(thing1))).to.eql JSON.parse(JSON.stringify(thing2))

hoistTest = (name, input, output) ->
  describe name, ->
    it '// hoists', ->
      eql scope(input), output
    it '// ignores', ->
      eql scope(output), output

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


describe "Scoper", ->

  it 'existential', ->
    expect(scope).to.exist

  # var hoisting raw commands
  # ====================================================================

  describe "var hoisting raw commands", ->

    hoistTest 'hoist 1 level root before',
        commands:
          [
            ['==',['get','foo'],100]
            ['rule',['.','box'],
              [
                ['==',['get','foo'],100]
              ]
            ]
          ]
      ,
        commands:
          [
            ['==',['get','foo'],100]
            ['rule',['.','box'],
              [
                ['==',['get',['^'],'foo'],100]
              ]
            ]
          ]


    hoistTest 'hoist 1 level root after',
        commands:
          [
            ['rule',['.','box'],
              [
                ['==',['get','foo'],100]
              ]
            ]
            ['==',['get','foo'],100]
          ]
      ,
        commands:
          [
            ['rule',['.','box'],
              [
                ['==',['get',['^'],'foo'],100]
              ]
            ]
            ['==',['get','foo'],100]
          ]

    hoistTest 'hoist 2 level before',
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
      ,
        commands:
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


    hoistTest 'hoist 2 level root after',
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
      ,
        commands:
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


    hoistTest 'DONT already hoisted 2 level root after',
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
      ,
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


    hoistTest 'conditionals',
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
      ,
        commands:
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

    hoistTest 'hoist 1 level root before',
        commands:
          [
            ['==',['get',['virtual','zone'],'foo'],100]
            ['rule',['.','box'],
              [
                ['==',['get',['virtual','zone'],'foo'],100]
              ]
            ]
          ]
      ,
        commands:
          [
            ['==',['get',['virtual','zone'],'foo'],100]
            ['rule',['.','box'],
              [
                ['==',['get',['virtual',['^'],'zone'],'foo'],100]
              ]
            ]
          ]

    hoistTest 'hoist 1 level root after',
        commands:
          [
            ['rule',['.','box'],
              [
                ['==',['get',['virtual','zone'],'foo'],100]
              ]
            ]
            ['==',['get',['virtual','zone'],'foo'],100]
          ]
      ,
        commands:
          [
            ['rule',['.','box'],
              [
                ['==',['get',['virtual',['^'],'zone'],'foo'],100]
              ]
            ]
            ['==',['get',['virtual','zone'],'foo'],100]
          ]

    hoistTest 'virtual defined in ruleset selector',
        commands:
          [
            ['rule',['.','box'],
              [
                ['rule',['virtual','zone'],
                  [
                    ['==',['get',['virtual','zone'],'foo'],100]
                  ]
                ]
                ['rule',['.','big'],
                  [
                    ['==',['get',['virtual','zone'],'foo'],100]
                  ]
                ]
              ]
            ]
          ]
      ,
        commands:
          [
            ['rule',['.','box'],
              [
                ['rule',['virtual','zone'],
                  [
                    ['==',['get',['virtual',['^'],'zone'],'foo'],100]
                  ]
                ]
                ['rule',['.','big'],
                  [
                    ['==',['get',['virtual',['^'],'zone'],'foo'],100]
                  ]
                ]
              ]
            ]
          ]


    hoistTest 'Dont hoist root',
        commands:
          [
            ['==',['get',['virtual','zone'],'foo'],100]
          ]
      ,
        commands:
          [
            ['==',['get',['virtual','zone'],'foo'],100]
          ]

    hoistTest 'Dont consider ruleset selector child scope',
        commands:
          [
            ['==',['get',['virtual','zone'],'foo'],100]
            ['rule', ['virtual','zone']
              [

              ]
            ]
          ]
      ,
        commands:
          [
            ['==',['get',['virtual','zone'],'foo'],100]
            ['rule', ['virtual','zone']
              [

              ]
            ]
          ]

    hoistTest '4 level',
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
      ,
        commands:
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

    equivalent "3 level with virtuals",
      """
        .wrap {
          my-size == 100;
          width: == &height == my-size;
          "target" {
            width: == &height == my-size;
            center-y: == ::window[center-y];
            center-x: ==        ^[center-x];
          }
          .thing {
            width: == &height == my-size;
            center: == "target"[center];
            .other {
              width: == &height == my-size / 2;
              center: == "target"[center];
            }
          }
        }
      """,
      """
        .wrap {
          my-size == 100;
          width: == &height == my-size;
          "target" {
            width: == &height == ^my-size;
            center-y: == ::window[center-y];
            center-x: ==        ^[center-x];
          }
          .thing {
            width: == &height == ^my-size;
            center: == ^"target"[center];
            .other {
              width: == &height == ^^my-size / 2;
              center: == ^^"target"[center];
            }
          }
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



