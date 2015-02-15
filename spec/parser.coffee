if window?
  parser = require 'gss-parser'
else
  chai = require 'chai' unless chai
  parser = require '../lib/parser'

{expect, assert} = chai

ok = (args...) ->
  args.push null
  parse.apply @, args

parse = (args...) ->
  if args.length is 3
    [name, sources, expectation] = args
  else
    [sources, expectation] = args
      
  itFn = it #if pending then xit else it

  if !(sources instanceof Array)
    sources = [sources]
    
  sources.forEach (source) ->
    if name 
      testName = name
      if sources.length > 1
        testName += " - #{sources.indexOf(source) + 1}"
    else 
      testName = source.trim().split("\n")[0]
    describe testName, ->
      result = null

      itFn 'ok ✓', ->
        result = parser.parse source
        expect(result).to.be.an 'object'

      if expectation
        itFn 'commands ✓', ->
          cleanResults = JSON.parse JSON.stringify result.commands
          cleanExpectation = JSON.parse JSON.stringify expectation.commands
          #console.log JSON.stringify cleanResults
          expect(cleanResults).to.eql cleanExpectation or []


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
          cleanResults = results[1]
          expect(cleanResults).to.eql results.splice(0,1)[0]


# Helper function for expecting errors to be thrown when parsing.
#
# @param source [String] CCSS statements.
# @param message [String] This should be provided when a rule exists to catch
# invalid syntax, and omitted when an error is expected to be thrown by the PEG
# parser.
# @param pending [Boolean] Whether the spec should be treated as pending.
#
expectError = (source, message, pending) ->
  itFn = if pending then xit else it

  describe source, ->
    predicate = 'should throw an error'
    predicate = "#{predicate} with message: #{message}" if message?

    itFn predicate, ->
      exercise = -> parser.parse source
      expect(exercise).to.throw Error, message


describe 'Parser', ->
  
  it 'existential', ->
    expect(parser.parse).to.be.a 'function'


# ====================================================================
describe "/* Expressions */", ->        
  
  # ------------------------------------------------------------------
  describe "/* Basics */", ->
  
    parse """
            foo == var;
          """
        ,
          {
            commands: [
              ['==',  ['get','foo'] , ['get','var']]
            ]
          }

    parse """
            10 <= 2 == 3 < 4 == 5 // chainning numbers, maybe should throw error?
          """
        ,
          {
            commands: [
              ['<=', 10, 2]
              ['==',  2 , 3]
              ['<',  3 , 4]
              ['==',  4 , 5]
            ]
          }

    parse [
            """
              [md-width] == ([width] * 2 - [gap] * 2) / 4 + 10 !require; // order of operations
            """
            """
              md-width   == ( width * 2 - gap * 2 ) / 4 + 10 !require; // order of operations
            """
          ]
        ,
          {
            commands: [
              ['==',
                ['get', 'md-width'],
                ['+'
                  [ '/',
                    ['-',
                      ['*', ['get','width'], 2],
                      ['*',['get','gap'],2]
                    ],
                    4
                  ],
                  10
                ],
                "require"]
            ]
          }


    parse [
            """
              [grid-height] * #box2[width] <= 2 == 3 < 4 == 5 // w/ multiple statements containing variables and getters
            """
            """
              grid-height * #box2[width]
                <= 2
                == 3
                < 4
                == 5;
            """
          ]
        ,
          {
            commands: [
              ['<=', [
                '*', ['get', 'grid-height'], ['get', ['#', 'box2'], 'width']
                ],
                2
              ]
              ['==', 2, 3]
              ['<', 3, 4]
              ['==', 4, 5]
            ]
          }

  # ------------------------------------------------------------------
  describe "Anonymous functions", ->
  
    parse ["""
            empty-func();
          """
          """
            empty-func(  );
          """
          """
            empty-func(  
            );
          """],
          {
            commands: [
              ['empty-func']
            ]
          }
  
    parse [
            "number-func(10.22);"
            "  number-func(  10.22  )  ;"
          ],
          {
            commands: [
              ['number-func',10.22]
            ]
          }
    
    parse [
            "math-func(10 + x * 2);"
          ],
          {
            commands: [
              ['math-func',['+',10,['*',['get','x'],2]]]
            ]
          }
  
    parse "selector-func(#foo.bar);",
          {
            commands: [
              ['selector-func',[['#','foo'],['.','bar']]] 
            ]
          }
    
    parse "var-func(my-var);",
          {
            commands: [
              ['var-func',['get','my-var']] 
            ]
          }
    
    parse "vars-func(my-var, #box[x], .foo.bar[x]);",
          {
            commands: [
              ['vars-func',
                ['get','my-var'],
                ['get',['#','box'],'x'],
                ['get',[['.','foo'],['.','bar']],'x']
              ] 
            ]
          }
    
    parse "nested functions", 
          [
            "outer(mid(inner()));"
            """
            outer(
              mid(
                inner( 
                )
              )
            )
            """
          ],
          {
            commands: [
              ['outer',
                ['mid'
                  ['inner']
                ]
              ] 
            ]
          }
    
    parse "functions as many params", 
          [
            "outer(inner(1),inner(2),inner(3));"
            """
            outer(
              inner( 1 ),
              inner( 2 ),
              inner( 3 )
            )
            """
          ],
          {
            commands: [
              ['outer',
                ['inner',1]
                ['inner',2]
                ['inner',3]
              ] 
            ]
          }
    
    parse "functions as many params", 
          [
            "outer(inner(1),inner(2),inner(3));"
            """
            outer(
              inner( 1 ),
              inner( 2 ),
              inner( 3 )
            )
            """
          ],
          {
            commands: [
              ['outer',
                ['inner',1]
                ['inner',2]
                ['inner',3]
              ] 
            ]
          }
    
    parse "unary operators as params", 
          [
            "dance(< 1, >= 1) jump(== 2) fall(+ 3, * 3, - my-func(1), / my-var);"
          ],
          {
            commands: [
              [ # chain
                ['dance',['<',1],['>=',1]]
                ['jump',['==',2]]
                ['fall',['+',3],['*',3],['-',['my-func',1]],['/',['get','my-var']]]
              ]
            ]
          }
    
    parse "nested function sequence", 
          [
            "dance(step(1) step(2) step(3)) jump(4);"
            
          ],
          {
            commands: [
              [ # chain
                ['dance',
                  [ # chain
                    ['step',1]
                    ['step',2]
                    ['step',3]
                  ]
                ]
                ['jump',4]
              ]
            ]
          }
    
  # ------------------------------------------------------------------
  describe "Functions in Equations", ->
  
    parse ["""
            x == my-spring(1);
          """],
          {
            commands: [
              ['==',
                ['get','x']
                ['my-spring',1]
              ]
            ]
          }
    
    parse ["""
            x == my-spring(1) + my-func(y);
          """],
          {
            commands: [
              ['==',
                ['get','x']                
                ['+'
                  ['my-spring',1]
                  ['my-func',['get','y']]
                ]
              ]
            ]
          }
    
    parse ["""
            x := my-spring(1 + 2) + my-func(y);
          """],
          {
            commands: [
              ['=',
                ['get',['&'],'x']           
                ['+'
                  ['my-spring',['+',1,2]]
                  ['my-func',['get','y']]
                ]
              ]
            ]
          }
    
    parse ["""
            x = a(#box[width]) b(1);
          """],
          {
            commands: [
              ['=',
                ['get','x']           
                [
                  ['a',['get',['#','box'],'width']]
                  ['b',1]
                ]
              ]
            ]
          }
  
  # ------------------------------------------------------------------
  describe '/* Parans */', ->

    parse """
            ((((#box1)[width]) + (("area")[width]))) == ((((#box2)[width]) + ((::window)[width])));
          """,
          {
            commands: [
              ['==',
                ['+',['get', ['#', 'box1'], 'width'], ['get', ['virtual', 'area'], 'width']],
                ['+',['get', ['#', 'box2'], 'width'], ['get', ['::window'], 'width']],
              ]
            ]
          }


# ====================================================================
describe "/* Strength */", ->

  parse """
          4 == 5 == 6 !strong10 // w/ strength and weight
        """,
        {
          commands: [
            ['==', 4, 5, 'strong', 10]
            ['==', 5, 6, 'strong', 10]
          ]
        }

  parse """
          div[width] == 100 !strong
        """,
        {
          commands: [
            ['==', ['get', ['tag', 'div'], 'width'], 100, 'strong']
          ]
        }

  # custom strengths accepted & lower cased
  parse """
          4 == 5 == 6 !my-custom-strength99;
          4 == 5 == 6 !My-CUSTOM-strengtH99;
        """,
        {
          commands: [
            ['==', 4, 5, 'my-custom-strength', 99]
            ['==', 5, 6, 'my-custom-strength', 99]
            ['==', 4, 5, 'my-custom-strength', 99]
            ['==', 5, 6, 'my-custom-strength', 99]
          ]
        }

  expectError '[a] == [b] !stron88afdklj23'
  expectError '[a] == [b] !strong0.5'

  #expectError '[a] == [b] !stron', 'Invalid Strength or Weight'



  

# ====================================================================
describe '/* Selectors */', ->

  # ------------------------------------------------------------------
  describe '/* New Pseudos */', ->

    parse [
            """
              &[width] == ::parent[width]
            """
            """
              &width == ::parent[width]
            """
          ],
          {
            commands: [
              ['==', ['get',['&'],'width'], ['get',['::parent'],'width']]
            ]
          }

    
    parse "viewport gets normalized to window", """
            ::scope[width] == ::this[width] == ::document[width] == ::viewport[width] == ::window[height]
          """,
          {
            commands: [
              ['==', ['get',['::scope'],'width'],    ['get',['&'],'width' ]]
              ['==', ['get',['&'],'width'],          ['get',['::document'],'width' ]]
              ['==', ['get',['::document'],'width'], ['get',['::window'],'width' ]]
              ['==', ['get',['::window'],'width'],   ['get',['::window'],'height']]
            ]
          }

    parse "normalize ::this selector", [
            """
              &width == &x == &y
            """
            """
              ::[width] == ::this[x] == &[y]
            """
            """
              /* parans ignored */
              (::)[width] == (::this)[x] == (&)[y]
            """
          ],
          {
            commands: [
              ['==', ['get',['&'],'width'],    ['get',['&'],'x']]
              ['==', ['get',['&'],'x'],        ['get',['&'],'y']]
            ]
          }

    parse "global scope selector", [
            """
              $width == $y
            """
            """
              $[width] == ($)[y]
            """
          ]
        ,
          {
            commands: [
              ['==', ['get',['$'],'width'], ['get',['$'],'y']]
            ]
          }

    # parent scope selector
    parse [
            """
              ^width == ^y
            """
            """
              ^[width] == (^)[y]
            """
          ]
        ,
          {
            commands: [
              ['==', ['get',['^'],'width'], ['get',['^'],'y']]
            ]
          }

    parse [
            """
              ^^margin-top == ^margin-top - margin-top
            """
            """
              ^^[margin-top] == ^[margin-top] - margin-top
            """
            """
              ( ^^ )[margin-top] == ( ^ )[margin-top] - [margin-top]
            """
          ]
        ,
          {
            commands: [
              ['==', ['get',['^', 2],'margin-top'], ['-',['get',['^'],'margin-top'],['get','margin-top']] ]
            ]
          }

    parse [
            """
              ^^^^^^^^--my-margin-top == ^^^--my-margin-top
            """
            """
              ^^^^^^^^[--my-margin-top] == ^^^[--my-margin-top]
            """
          ]
        ,
          {
            commands: [
              ['==', ['get',['^',8],'--my-margin-top'], ['get',['^',3],'--my-margin-top'] ]
            ]
          }

    parse "^[left] + [base] == &[left]",
          {
            commands: [
              ['==', ['+',['get',['^'],'x'],['get','base']] , ['get',['&'],'x'] ]
            ]
          }


  # ------------------------------------------------------------------
  describe '/* Selectors as selector call context */', ->

    parse """
            &(.box)[width] == ::parent(.thing)[width]
          """
        ,
          {
            commands: [
              ['==',
                ['get',[['&'],[['.','box']]],'width'],
                ['get',[['::parent'],[['.','thing']]],'width']
              ]
            ]
          }

    parse """
            button.big(.text)[width] == 100
          """
        ,
          {
            commands: [
              ['==',
                ['get',
                  [
                    ['tag','button'],
                    ['.','big'],
                    [['.','text']]
                  ],
                  'width'
                ],
                100
              ]
            ]
          }


  # ------------------------------------------------------------------
  describe '/ "Virtuals" /', ->

    parse """
            "Zone"[width] == 100;
          """
        ,
          {
            commands: [
              ['==', ['get',['virtual','Zone'],'width'],100]
            ]
          }

    parse """
            "A"[left] == "1"[top];
          """
        ,
          {
            commands: [
              ['==', ['get',['virtual','A'],'x'],['get',['virtual','1'],'y']]
            ]
          }

    parse '"box"[right] == "box2"[left];',
          {
            commands: [
              ['==', ['get',['virtual','box'],'right'],['get',['virtual','box2'],'x']]
            ]
          }


  # ------------------------------------------------------------------
  describe '/* Selector Splats */', ->
    
    # ................................................................
    describe '/* Basics */', ->
      
      parse [
              """
                "col1...5"[x] == 0; // virtual splats
              """,
              """
                ("col1","col2","col3","col4","col5")[x] == 0;
              """
            ]
          ,
            {
              commands: [
                ['==',
                  ['get',
                    [',',
                      ['virtual','col1']
                      ['virtual','col2']
                      ['virtual','col3']
                      ['virtual','col4']
                      ['virtual','col5']
                    ],
                    'x'
                  ],
                  0
                ]
              ]
            }

      equivalent "/* Virtual Splats Constraints */",
        '"col-1...4"[x] == 0;',
        '("col-1","col-2","col-3","col-4")[x] == 0;',
        '("col-1","col-2...3","col-4")[x] == 0;',
        '("col-1...2","col-3...3","col-4...4")[x] == 0;'


      equivalent "/* Virtual Splats Rulesets */", """
          "col1...5" { x: == 0; }
        """,
        """
          "col1...1","col2...2","col3...3","col4...4","col5...5" { &[x] == 0; }
        """,
        """
          "col1","col2","col3","col4","col5" { &[x] == 0; }
        """,
        """
          "col1","col2...4","col5" { &[x] == 0; }
        """,
        """
          "col1...3","col4...5" { &[x] == 0; }
        """

      parse '"zone-1-1...3"[x] == 0',
        {
          commands: [
            ['==',
              ['get',
                [',',
                  ['virtual','zone-1-1']
                  ['virtual','zone-1-2']
                  ['virtual','zone-1-3']
                ],
                'x'
              ],
              0
            ]
          ]
        }

      parse '"zone-1...3-1...3"[x] == 0',
        {
          commands: [
            ['==',
              ['get',
                [',',
                  ['virtual','zone-1-1']
                  ['virtual','zone-1-2']
                  ['virtual','zone-1-3']
                  ['virtual','zone-2-1']
                  ['virtual','zone-2-2']
                  ['virtual','zone-2-3']
                  ['virtual','zone-3-1']
                  ['virtual','zone-3-2']
                  ['virtual','zone-3-3']
                ],
                'x'
              ],
              0
            ]
          ]
        }

      parse '"zone-1...3-2"[x] == 0',
        {
          commands: [
            ['==',
              ['get',
                [',',
                  ['virtual','zone-1-2']
                  ['virtual','zone-2-2']
                  ['virtual','zone-3-2']
                ],
                'x'
              ],
              0
            ]
          ]
        }

      parse "#box-2...6[x] == 0",
        {
          commands: [
            ['==',
              ['get',
                [',',
                  ['#','box-2']
                  ['#','box-3']
                  ['#','box-4']
                  ['#','box-5']
                  ['#','box-6']
                ],
                'x'
              ],
              0
            ]
          ]
        }

      parse "#cell-x1...2-y1...2-z1...2[z] == 0",
        {
          commands: [
            ['==',
              ['get',
                [',',
                  ['#','cell-x1-y1-z1']
                  ['#','cell-x1-y1-z2']
                  ['#','cell-x1-y2-z1']
                  ['#','cell-x1-y2-z2']
                  ['#','cell-x2-y1-z1']
                  ['#','cell-x2-y1-z2']
                  ['#','cell-x2-y2-z1']
                  ['#','cell-x2-y2-z2']
                ],
                'z'
              ],
              0
            ]
          ]
        }

      parse [
          ".btn0...2.featured[x]                <= 0"
          "((.btn0, .btn1, .btn2).featured)[x]  <= 0"
        ]
        {
          commands: [
            ['<=',
              ['get',
                [
                  [',',
                    ['.','btn0']
                    ['.','btn1']
                    ['.','btn2']
                  ],
                  ['.', 'featured']
                ],
              'x'],
              0
            ]
          ]
        }

    # ................................................................
    describe '/* scoped splats */', ->

      parse ".parent.btn0...2.featured[x] <= 0",
        {
          commands: [
              ['<=',
                ['get',
                  [
                    ['.', 'parent']
                    [',',
                        ['.', 'btn0']
                        ['.', 'btn1']
                        ['.', 'btn2']
                    ]
                    ['.', 'featured']
                  ],
                'x'],
              0
              ]
            ]
        }

      parse "$.btn0...2[x] <= 0",

        {
          commands: [
            ['<=',
              ['get',
                [
                  ['$'],
                  [',',
                      ['.','btn0']
                      ['.','btn1']
                      ['.','btn2']
                  ]
                ],
              'x'],
              0
            ]
          ]
        }


      parse '$"zone-1...3-2"[x] == 0',
        {
          commands: [
            ['==',
              ['get',
                [
                  ['$'],
                  [',',
                    ['virtual','zone-1-2']
                    ['virtual','zone-2-2']
                    ['virtual','zone-3-2']
                  ],
                ],
                'x'
              ],
              0
            ]
          ]
        }

    # ................................................................
    describe '/* Special Splat Optimizations */', ->

      parse [
          '"col1...3":first[x] == 0'
          '(("col1", "col2", "col3"):first)[x] == 0'
        ]
        {
          commands: [
            ['==',
              ['get',
                ['virtual','col1']
              'x'],
              0
            ]
          ]
        }

      parse [
          '"col1...3":last[x] == 0'
          '(("col1", "col2", "col3"):last)[x] == 0',
        ]
        {
          commands: [
            ['==',
              ['get',
                ['virtual','col3']
              'x'],
              0
            ]
          ]
        }

  # ------------------------------------------------------------------
  describe '/* Advanced Selectors */', ->

    parse """
            (html #main .boxes)[width] == 100
          """
        ,
          {
            commands: [
              ['==', ['get', [["tag", "html"], [" "], ["#","main"], [" "], [".","boxes"]],'width',], 100]
            ]
          }

    parse """/* pseudo selector options */
            :sel(.thing.other:sel(.inner)):num(1401):string('hello'):empty()[width] == 100
          """
        ,
          {
            commands: [
              ['==', 
                ['get',
                  [
                    [':sel',[['.','thing'],['.','other'],[':sel',['.','inner']]]]
                    [':num',1401]
                    [':string',"'hello'"]
                    [':empty']
                  ], 
                  'width'], 
                100
              ]
            ]
          }
  
    parse """
            (* #main:not(.disabled) .boxes[data-target])[width] == 100
          """
        ,
          {
            commands: [
              ['==', ['get', [['tag','*'], [' '], ['#', 'main'], [':not', ['.', 'disabled']], [' '], ['.', 'boxes'], ['[]', 'data-target']], 'width'], 100]
            ]
          }


    parse """
            (header !> h2.gizoogle ! section div:get('parentNode'))[target-size] == 100
          """
        ,
          {
            commands: [
              ['==', ['get', [['tag', 'header'], ['!>'], ['tag', 'h2'], ['.', 'gizoogle'], ['!'], ['tag', 'section'], [' '], ['tag', 'div'], [':get', "'parentNode'"]], 'target-size'], 100]
            ]
          }

    parse """
            (&.featured)[width] == 100;
          """
        ,
          {
            commands: [
              ['==', ['get', [['&'], ['.','featured']], 'width'], 100]
            ]
          }

    parse """
            (&"column2")[width] == 100;
             &"column2"[width]  == 100;
          """
        ,
          {
            commands: [
              ['==',
                ['get',[['&'], ['virtual','column2']],'width'],
                100
              ],
              ['==',
                ['get',[['&'], ['virtual','column2']],'width'],
                100
              ]
            ]
          }

    parse """
            (&:next)[left] == 666;
            &:previous[left] == 111;
          """
        ,
          {
            commands: [
              ['==',
                ['get',[['&'], [':next']],'x'],
                666
              ],
              ['==',
                ['get',[['&'], [':previous']],'x'],
                111
              ]
            ]
          }

    parse """
            &:next.selected[width] == &:previous.selected[width];
          """
        ,
          {
            commands: [
              ['==',
                ['get',[['&'], [':next'], ['.', 'selected']], 'width'],
                ['get',[['&'], [':previous'], ['.', 'selected']], 'width']
              ]
            ]
          }

    parse """
            ([foo~="bar"])[x] == ([foo!="bar"])[x];
            ([foo$="bar"])[x] == ([foo*="bar"])[x];
            ([foo ^= "bar"])[x] == ([foo  = "bar"])[x];
          """
        ,
          {
            commands: [
              ['==',
                ['get',['[~=]','foo','"bar"'],'x']
                ['get',['[!=]','foo','"bar"'],'x']
              ]
              ['==',
                ['get',['[$=]','foo','"bar"'],'x']
                ['get',['[*=]','foo','"bar"'],'x']
              ]
              ['==',
                ['get',['[^=]','foo','"bar"'],'x']
                ['get',['[=]','foo','"bar"'],'x']
              ]
            ]
          }

    parse """
            (::parent[disabled] ~ li:first)[width] == 100
          """
        ,
          {
            commands: [
              ['==', ['get', [['::parent'], ['[]', 'disabled'], ['~'], ['tag', 'li'], [':first']], 'width'], 100]
            ]
          }

    parse """
        ((#a, #b).c, (#x, #y).z)[a-z] == 0;
      """,
      {
        commands: [
          ['==',
            ['get',
              [',',
                [
                  [',',
                    ['#', 'a'], ['#', 'b']
                  ],
                  ['.', 'c']
                ],
                [
                  [',',
                    ['#', 'x'], ['#', 'y']
                  ],
                  ['.', 'z']
                ]
              ],
              'a-z'
            ],
            0
          ]
        ]
      }

    parse [ """
              (&"grid", .that"grid" , .box ,.thing)[width] == 100
            """
            """
              (
                &"grid"
                ,
                .that"grid" ,
                .box,.thing
              )[width] == 100
            """
          ]
          {
            commands: [
              ['==',
                [
                  'get',
                  [
                     ",",
                     [["&"], ["virtual","grid"]],
                     [[".","that"], ["virtual","grid"]]
                     [".","box"]
                     [".","thing"]
                  ],
                  'width',
                ],
                100
              ]
            ]
          }


# ====================================================================
describe "/* Rulesets */", ->

  # ------------------------------------------------------------------
  describe "/* inline ruleset statements */", ->

    parse ["""
            x: == 100;
            x: =  100;
            x: <= 100;
            x: <  100;
            x: >= 100;
            x: >  100;
          """
          """
            x :== 100;
            x :=  100;
            x :<= 100;
            x :<  100;
            x :>= 100;
            x :>  100;
          """]
        ,
          {
            commands: [
              ['==',['get',['&'],'x'],100]
              ['=', ['get',['&'],'x'],100]
              ['<=',['get',['&'],'x'],100]
              ['<', ['get',['&'],'x'],100]
              ['>=',['get',['&'],'x'],100]
              ['>', ['get',['&'],'x'],100]
            ]
          }
        
    parse """
            y: 100px;
          """
        ,
          {
            commands: [
              ['set','y','100px']
            ]
          }

    parse """

            x  :<= &[y];

            y  : 100px;

            z  :>= &[y];

          """
        ,
          {
            commands: [
              ['<=',
                ['get',['&'],'x']
                ['get',['&'],'y']
              ]
              ['set','y','100px']
              ['>=',
                ['get',['&'],'z']
                ['get',['&'],'y']
              ]
            ]
          }
  

  # ------------------------------------------------------------------
  describe "/* Ruleset Basics */", ->

    parse """
          #box.class {

            color: blue;
            x: == 100;
          }
          """
        ,
          {
            commands: [
              ['rule',
                [['#','box'], ['.', 'class']]
                [
                  ['set','color','blue']
                  ['==',['get',['&'],'x'],100]
                ]
              ]
            ]
          }

    parse """
          .class.foo, .class.bar {
            color: blue;
          }
          """
        ,
          {
            commands: [
              ['rule',
                [',',
                  [['.','class'], ['.','foo']]
                  [['.','class'], ['.','bar']]
                ]
                [
                  ['set','color','blue']
                ]
              ]
            ]
          }

    parse """
          article.featured > img {

            color: black;

            .bg"face" {

              &[x] == [y];

            }

            color: black;
          }
          """
        ,
          {
            commands: [
              ['rule',
                [['tag', 'article'], ['.', 'featured'], ['>'], ['tag', 'img']]
                [
                  ['set','color','black']
                  ['rule',
                    [['.','bg'],['virtual','face']]
                    [
                      ['==',
                        ['get',['&'],'x']
                        ['get','y']
                      ]
                    ]
                  ]
                  ['set','color','black']
                ]
              ]
            ]
          }

    parse """
          article.featured > img {

          }
          """
        ,
          {
            commands: [
              ['rule',
                [['tag', 'article'], ['.', 'featured'], ['>'], ['tag', 'img']]
                []
              ]
            ]
          }

    parse [ """
              ::this, ::scope .box, ::this .post, ::scope, ::this "fling" {
              }
            """,
            """
              (::this), (::scope .box), (::this .post), (::scope), (::this "fling") {
              }
            """,
            """
              ((::this), (::scope .box), (::this .post), (::scope), (::this "fling")) {
              }
            """
          ]
        ,
          {
            commands: [
              [
                "rule",
                [
                  ",",
                  ["&"],
                  [["::scope"], [" "], [".", "box"]],
                  [["&"], [" "], [".", "post"]],
                  ["::scope"],
                  [["&"], [" "], ["virtual", "fling"]]
                ],
                []
              ]
            ]
          }



# ====================================================================
describe "/* Directives */", ->

  parse """
        @my-custom-directive blah blah blah {
          color: blue;
        }
        """,
        {
          commands: [
            ['directive',
              'my-custom-directive',
              'blah blah blah',
              [
                ['set','color','blue']
              ]
            ]
          ]
        }

  parse """
        @my-custom-directive blah blah blah {
          @my-other-directive blah... {
          }
        }
        """
      ,
        {
          commands: [
            [ 'directive',
              'my-custom-directive',
              'blah blah blah',
              [
                [ 'directive',
                  'my-other-directive',
                  'blah...',
                  []
                ]
              ]
            ]
          ]
        }

  parse """
        @my-custom-directive blah blah blah;
        """
      ,
        {
          commands: [
            [ 'directive',
              'my-custom-directive',
              'blah blah blah'
            ]
          ]
        }


  # ------------------------------------------------------------------
  describe "/* If Else */", ->

    parse """
          @if [x] >= 100 {
            font-family: awesome;
          }
          """
        ,
          {
            commands: [
              ['if',
                ['>=',['get','x'],100]
                [
                  ['set', 'font-family', 'awesome']
                ]
              ]
            ]
          }

    parse [
            """
              @if [x] != 20 && [y] == 200 {
              }
              @else {
              }
            """,
            """
              @if[x]!=20&&[y]==200{}@else{}
            """
          ]
        ,
          {
            commands: [
              ['if',
                ['&&',['!=',['get','x'],20],['==',['get','y'],200]]
                []
                [
                  true
                  []
                ]
              ]
            ]
          }

    parse [
            """
              @if [x]
              {

                font-family: awesome;
                font-family: awesomer;

              }
              @else
              {
                font-family: lame;

                font-family: lamer;
              }
            """,
            """
              @if[x]{font-family:awesome;font-family:awesomer;}@else{font-family:lame;font-family:lamer;}
            """
          ]
        ,
          {
            commands: [
              ['if',
                ['get','x']
                [['set', 'font-family', 'awesome'],['set', 'font-family', 'awesomer']]
                [
                  true
                  [['set', 'font-family', 'lame'],['set', 'font-family', 'lamer']]
                ]
              ]
            ]
          }

    parse [
            """
              @if [x] {
                font-family: awesome;
              }
              @else [y] {
                font-family: awesomer;
              }
              @else [z] {
                font-family: awesomest;
              }
            """
          ]
        ,
          {
            commands: [
              ['if',
                ['get','x']
                [['set', 'font-family', 'awesome']]
                [
                  ['get','y']
                  [['set', 'font-family', 'awesomer']]
                ]
                [
                  ['get','z']
                  [['set', 'font-family', 'awesomest']]
                ]
              ]
            ]
          }

    parse [
            """
            .outie {
              @if [x] > [xx] {
                font-family: awesome;
                .innie {
                  color:blue;
                }
              }
              @else [y] {
                font-family: awesomer;
                .innie {
                  color:red;
                }
              }
              @else [z] {
                font-family: awesomest;
                .innie {
                  color:pink;
                }
              }
            }
            """
          ]
        ,
          {
            commands: [
              ['rule'
                ['.', 'outie'],
                [['if',
                  ['>',['get','x'],['get','xx']]
                  [
                    ['set', 'font-family', 'awesome']
                    ['rule'
                      ['.', 'innie']
                      [['set', 'color', 'blue']]
                    ]
                  ],
                  [
                    ['get','y']
                    [
                      ['set', 'font-family', 'awesomer']
                      ['rule'
                        ['.', 'innie']
                        [['set', 'color', 'red']]
                      ]
                    ]
                  ]
                  [
                    ['get','z']
                    [
                      ['set', 'font-family', 'awesomest']
                      ['rule'
                        ['.', 'innie']
                        [['set', 'color', 'pink']]
                      ]
                    ]
                  ]
                ]]
              ]
            ]
          }

    parse [
            """
              @if [x] {
                @if [x] {
                  @if [x] {
                  }
                  @else {
                  }
                }
                @else {
                }
              }
              @else {
                @if [x] {
                }
                @else {
                }
              }
            """
            # Throws Range Error?
            #"""
            #  @if [x] { @if [x] { @if [x] { } @else {} }
            #    @else {
            #    }
            #  }
            #  @else {
            #    @if [x] {
            #    }
            #    @else {
            #    }
            #  }
            #"""
          ]
        ,
          {
            commands: [
              ['if',
                ['get','x']
                [
                  ['if',
                    ['get','x']
                    [
                      ['if',
                        ['get','x']
                        []
                        [
                          true
                          []
                        ]
                      ]
                    ]
                    [
                      true
                      []
                    ]
                  ]
                ]
                [
                  true
                  [
                    ['if',
                      ['get','x']
                      []
                      [
                        true
                        []
                      ]
                    ]
                  ]
                ]
              ]
            ]
          }

    parse """
            @if #box[right] == #box2[x] {}
          """
        ,
          {
            commands: [
              ['if',
                ['==', ['get',['#','box'],'right'], ['get',['#','box2'],'x']]
                []
              ]
            ]
          }

    parse """
            @if 2 * [right] == [x] + 100 {}
          """
        ,
          {
            commands: [
              ['if',
                ['==',['*',2,['get','right']], ['+',['get','x'],100] ]
                []
              ]
            ]
          }

    parse """
            @if (#box[right] != #box2[x]) AND (#box[width] <= #box2[width]) {}
          """
        ,
          {
            commands: [
              [ "if"
                ["&&"
                  ['!=', ['get',['#','box'],'right'], ['get',['#','box2'],'x'    ]],
                  ['<=', ['get',['#','box'],'width'], ['get',['#','box2'],'width']]
                ]
                []
              ]
            ]
          }

    conditionCommands = [
        "&&"
        ['!=', ['get',['#','box'],'right'], ['get',['#','box2'],'x']],
        ["||"
          ['<=', ['get',['#','box'],'width'], ['get',['#','box2'],'width']],
          ['==', ['get','x'],100]
        ]
      ]
    parse """
            @if     (#box[right] != #box2[x]) and (#box[width] <= #box2[width] or [x] == 100) {
            }
            @else   (#box[right] != #box2[x]) and (#box[width] <= #box2[width] or [x] == 100) {
            }
            @else   (#box[right] != #box2[x]) and (#box[width] <= #box2[width] or [x] == 100) {
            }
            @else {
            }
            @if     (#box[right] != #box2[x]) and (#box[width] <= #box2[width] or [x] == 100) {
              @if   (#box[right] != #box2[x]) and (#box[width] <= #box2[width] or [x] == 100) {
                @if (#box[right] != #box2[x]) and (#box[width] <= #box2[width] or [x] == 100) {
                }
                @else {
                }
              }
              @else {
              }
            }
            @else {}
          """
        ,
          {
            commands: [
              [ "if"
                conditionCommands
                []
                [
                  conditionCommands
                  []
                ]
                [
                  conditionCommands
                  []
                ]
                [ true, [] ]
              ]
              [ "if"
                conditionCommands
                [
                  [ "if"
                    conditionCommands
                    [
                      [ "if"
                        conditionCommands
                        []
                        [ true, [] ]
                      ]
                    ]
                    [ true, [] ]
                  ]
                ]
                [ true, [] ]
              ]
            ]
          }



    # what to do with strings?
    #parse """
    #      @if [font-family] == 'awesome-nueu' {
    #        z: == 100;
    #      }
    #      @else {
    #        z: == 1000;
    #      }
    #      """
    #    ,
    #      {
    #        commands: [
    #          ['if',
    #            ['==', ['get','x'],20]
    #            [
    #              ['set', 'font-family', 'awesome']
    #            ]
    #          ]
    #        ]
    #      }


  # ------------------------------------------------------------------
  describe "/* Stays */", ->

    parse """
            @-gss-stay #box[width], [grid-height];
          """
        ,
          {
            commands: [
              ['stay',['get',['#','box'],'width'],['get','grid-height']]
            ]
          }
    parse """
            @stay #box[width], [grid-height];
          """
        ,
          {
            commands: [
              ['stay',['get',['#','box'],'width'],['get','grid-height']]
            ]
          }



# ====================================================================
describe "/* Normalize Prop Names */", ->

  parse """
          #b[left] == [left];
          [left-col] == [col-left];
        """
      ,
        {
          commands: [
            ['==', ['get', ['#', 'b'], 'x'], ['get', 'left']]
            ['==', ['get', 'left-col'], ['get', 'col-left']]
          ]
        }
  parse """
          #b[top] == [top];
        """
      ,
        {
          commands: [
            ['==',['get',['#','b'],'y'],['get','top']]
          ]
        }

  parse """
          [right] == ::window[right];
        """
      ,
        {
          commands: [
            ['==',['get','right'],['get',['::window'],'width']]
          ]
        }
  parse """
          [left] == ::window[left];
        """
      ,
        {
          commands: [
            ['==', ['get','left'], ['get',['::window'],'x']]
          ]
        }
  parse """
          [top] == ::window[top];
        """
      ,
        {
          commands: [
            ['==', ['get', 'top'], ['get',['::window'],'y']]
          ]
        }
  parse """
          [bottom] == ::window[bottom];
        """
      ,
        {
          commands: [
            ['==', ['get','bottom'], ['get',['::window'],'height']]
          ]
        }

  parse """
          #b[cx] == [cx];
        """
      ,
        {
          commands: [
            ['==', ['get',['#', 'b'],'center-x'], ['get', 'cx']]
          ]
        }
  parse """
          #b[cy] == [cy];
        """
      ,
        {
          commands: [
            ['==', ['get',['#', 'b'],'center-y'], ['get', 'cy']]
          ]
        }


# ====================================================================
describe '/* Decimals & Negatives */', ->

  parse """
          [left] == 0.4; // with leading zero
        """
        ,
          {
            commands: [
              ['==', ['get', 'left'], 0.4]
            ]
          }

  parse """
          [left] == .4; // without leading zero
          [left] == .004;
        """
        ,
          {
            commands: [
              ['==', ['get', 'left'], 0.4  ]
              ['==', ['get', 'left'], 0.004]
            ]
          }

  parse """
          [left] == 0 - 1; // negative via additive expression
        """
        ,
          {
            commands: [
              ['==', ['get', 'left'], ['-', 0, 1]]
            ]
          }

  parse """
          [left] == (0 - 1); // negative via additive expression with parentheses
        """
        ,
          {
            commands: [
              ['==', ['get', 'left'], ['-', 0, 1]]
            ]
          }

  parse """
          [left] == 0-1; // negative via additive expression without spaces
        """
        ,
          {
            commands: [
              ['==', ['get', 'left'], ['-', 0, 1]]
            ]
          }

  parse """
          [left] == -1; // negative without additive expression
        """
        ,
          {
            commands: [
              ['==', ['get', 'left'], -1]
            ]
          }

  parse """
          [left] == -0.4; // negative floating point with leading zero
        """
        ,
          {
            commands: [
              ['==', ['get', 'left'], -0.4]
            ]
          }

  parse """
          [left] == -.4; // negative floating point without leading zero
        """
        ,
          {
            commands: [
              ['==', ['get', 'left'], -0.4]
            ]
          }

  parse """
          [left] == 0 + 1; // positive via additive expression
        """
        ,
          {
            commands: [
              ['==', ['get', 'left'], ['+', 0, 1]]
            ]
          }

  parse """
          [left] == (0 + 1); // positive via additive expression with parentheses
        """
        ,
          {
            commands: [
              ['==', ['get', 'left'], ['+', 0, 1]]
            ]
          }

  parse """
          [left] == 0+1; // positive via additive expression without spaces
        """
        ,
          {
            commands: [
              ['==', ['get', 'left'], ['+', 0, 1]]
            ]
          }

  parse """
          [left] == +1; // positive without additive expression
        """
        ,
          {
            commands: [
              ['==', ['get', 'left'], 1]
            ]
          }

  parse """
          [left] == +0.4; // positive floating point with leading zero
        """
        ,
          {
            commands: [
              ['==', ['get', 'left'], 0.4]
            ]
          }

  parse """
          [left] == +.4; // positive floating point without leading zero
        """
        ,
          {
            commands: [
              ['==', ['get', 'left'], 0.4]
            ]
          }

    parse """
            -[x] == -[y]; // unary minus
          """
          ,
            {
              commands: [
                ['==', ['-',0,['get', 'x']], ['-',0,['get','y']]]
              ]
            }

    parse """
            -1 - -[x] == -[y] - -1; // minus unary minus
          """
          ,
            {
              commands: [
                ['==',
                  ['-', -1, ['-',0,['get', 'x']]],
                  ['-', ['-',0,['get','y']], -1]
                ]
              ]
            }

    parse """
            -1 + -[x] == -[y] - -[x]; // unary minus - unary minus
          """
          ,
            {
              commands: [
                ['==',
                  ['+', -1, ['-',0,['get', 'x']]],
                  ['-', ['-',0,['get','y']], ['-',0,['get', 'x']]]
                ]
              ]
            }


# ====================================================================
describe '/* Units */', ->
  
  # ------------------------------------------------------------------
  describe "/* Units with numbers */", ->

    parse """
            10px == 0.4px;
            -.01px == .01px;
          """
          ,
            {
              commands: [
                ['==', ['px', 10], ['px', 0.4]]
                ['==', ['px', -0.01], ['px', 0.01]]
              ]
            }

    parse """
            10em == 0.4em;
            -.01em == .01em;
          """
          ,
            {
              commands: [
                ['==', ['em', 10], ['em', 0.4]]
                ['==', ['em', -0.01], ['em', 0.01]]
              ]
            }

    parse """
            10% == 0.4%;
            -.01% == .01%;
          """
          ,
            {
              commands: [
                ['==', ['%', 10], ['%', 0.4]]
                ['==', ['%', -0.01], ['%', 0.01]]
              ]
            }
  
    parse """/* custom units */
            10my-md == 0.4my-md;
            -.01my-md == .01my-md;
          """
          ,
            {
              commands: [
                ['==', ['my-md', 10], ['my-md', 0.4]]
                ['==', ['my-md', -0.01], ['my-md', 0.01]]
              ]
            }
  
  # ------------------------------------------------------------------
  describe "/* Units with vars */", ->

    parse """
            x px == y em;
          """
          ,
            {
              commands: [
                ['==', ['px', ['get','x']], ['em', ['get','y']]]
              ]
            }
    
    parse [
            """
            x px == y    + z em;
            x px == y vw + z em;
            """
            """
            x  px == y         +   z   em;
            x  px == y     vw  +   z   em;
            """
            """
             (x)   px == (y       )  +   (z   )em;
            ( x )  px == (y     vw)  +   (z   )em;
            """
          ]
          ,
            {
              commands: [
                ['==', 
                  ['px', ['get','x']], 
                  ['+',
                    ['get','y'],
                    ['em',['get','z']],
                  ]
                ]
                ['==', 
                  ['px', ['get','x']], 
                  ['+',
                    ['vw',['get','y']],
                    ['em',['get','z']],
                  ]
                ]
              ]
            }
      
      parse [
              """
              shoe uk-foot-size == hand in + head ft * arm meter;
              """
              """
              shoe uk-foot-size == hand in + (head ft * arm meter);
              """
            ]
            ,
              {
                commands: [
                  ['==', 
                    ['uk-foot-size', ['get','shoe']], 
                    ['+',
                      ['in',['get','hand']],
                      ['*',
                        ['ft',['get','head']],
                        ['meter',['get','arm']],
                      ]
                    ]
                  ]
                ]
              }
      
      parse [
              """
              shoe uk-foot-size == ((hand in + head) ft * arm) meter;
              """
            ]
            ,
              {
                commands: [
                  ['==', 
                    ['uk-foot-size', ['get','shoe']], 
                    ['meter',['*',
                      ['ft',['+',
                        ['in',['get','hand']],
                        ['get','head']
                      ]]
                      ['get','arm'],
                    ]]
                  ]
                ]
              }

        
# ====================================================================
describe '/* Smoke Tests */', ->
  
  ok """/* kitchen sink */
      /* vars */
      [gap] == 20 !require;
      [flex-gap] >= [gap] * 2 !require;
      [radius] == 10 !require;
      [outer-radius] == [radius] * 2 !require;

      /* elements */
      #profile-card {
        width: == ::window[width] - 480;
        height: == ::window[height] - 480;
        center-x: == ::window[center-x];
        center-y: == ::window[center-y];
        border-radius: == [outer-radius];
      }

      #avatar {
        height: == 160 !require;
        width: == ::[height];
        border-radius: == ::[height] / 2;
      }

      #name {
        height: == ::[intrinsic-height] !require;
        width: == ::[intrinsic-width] !require;
      }

      #cover {
        border-radius: == [radius];
      }

      button {
        width: == ::[intrinsic-width] !require;
        height: == ::[intrinsic-height] !require;
        padding: == [gap];
        padding-top: == [gap] / 2;
        padding-bottom: == [gap] / 2;
        border-radius: == [radius];
      }

      @h |~-~(#name)~-~| in(#cover) gap([gap]*2) !strong;

      /* landscape profile-card */
      @if #profile-card[width] >= #profile-card[height] {

        @v |
            -
            (#avatar)
            -
            (#name)
            -
           |
          in(#cover)
          gap([gap]) outer-gap([flex-gap]) {
            center-x: == #cover[center-x];
        }

        @h |-10-(#cover)-10-|
          in(#profile-card);

        @v |
            -10-
            (#cover)
            -
            (#follow)
            -
           |
          in(#profile-card)
          gap([gap]);

        #follow[center-x] == #profile-card[center-x];

        @h |-(#message)~-~(#follow)~-~(#following)-(#followers)-|
          in(#profile-card)
          gap([gap])
          !strong {
            &[top] == &:next[top];
          }
      }

      /* portrait profile-card */
      @else {
        @v |
            -
            (#avatar)
            -
            (#name)
            -
            (#follow)
            -
            (#message)
            -
            (#following)
            -
            (#followers)
            -
           |
          in(#cover)
          gap([gap])
          outer-gap([flex-gap]) {
            center-x: == #profile-card[center-x];
        }

        @h |-10-(#cover)-10-| in(#profile-card);
        @v |-10-(#cover)-10-| in(#profile-card);
      }


  """
