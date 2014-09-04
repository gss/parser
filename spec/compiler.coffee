if window?
  parser = require 'ccss-compiler'
else
  chai = require 'chai' unless chai
  parser = require '../lib/compiler'

{expect} = chai


parse = (sources, expectation, pending) ->
  itFn = if pending then xit else it
  
  if !(sources instanceof Array)
    sources = [sources]
  for source in sources
    describe source, ->
      result = null

      itFn 'should do something', ->
        result = parser.parse source
        expect(result).to.be.an 'object'
      itFn 'commands ✓', ->
        expect(result.commands).to.eql expectation.commands or []


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


describe 'CCSS-to-AST', ->
  it 'should provide a parse method', ->
    expect(parser.parse).to.be.a 'function'

  # Basics
  # ====================================================================

  describe "/* Basics */", ->

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

    parse """
            [md-width] == ([width] * 2 - [gap] * 2) / 4 + 10 !require; // order of operations
          """
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


    parse """
            [grid-height] * #box2[width] <= 2 == 3 < 4 == 5 // w/ multiple statements containing variables and getters
          """
        ,
          {
            commands: [
              ['<=', [
                '*', ['get', 'grid-height'], ['get', ['$id', 'box2'], 'width']
                ],
                2
              ]
              ['==', 2, 3]
              ['<', 3, 4]
              ['==', 4, 5]
            ]
          }


  # Strength
  # ====================================================================

  describe "/* Strength */", ->

    parse """
            4 == 5 == 6 !strong10 // w/ strength and weight
          """
        ,
          {
            commands: [
              ['==', 4, 5, 'strong', 10]
              ['==', 5, 6, 'strong', 10]
            ]
          }
    
    # custom strengths accepted & lower cased
    parse """
            4 == 5 == 6 !my-custom-strength99;
            4 == 5 == 6 !My-CUSTOM-strengtH99;
          """
        ,
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
    



  # Pseudos
  # ====================================================================

  describe '/* Reserved Pseudos */', ->

    parse """
            ::[width] == ::parent[width]
          """
        ,
          {
            commands: [
              ['==', ['get',['$reserved','this'],'width'], ['get',['$reserved', 'parent'],'width']]
            ]
          }

    # viewport gets normalized to window
    parse """
            ::scope[width] == ::this[width] == ::document[width] == ::viewport[width] == ::window[height]
          """
        ,
          {
            commands: [
              ['==', ['get',['$reserved','scope'],'width'],    ['get',['$reserved','this'],'width' ]]
              ['==', ['get',['$reserved','this'],'width'],     ['get',['$reserved','document'],'width' ]]
              ['==', ['get',['$reserved','document'],'width'], ['get',['$reserved','window'],'width' ]]
              ['==', ['get',['$reserved','window'],'width'],   ['get',['$reserved','window'],'height']]
            ]
          }
    
    # normalize ::this selector
    
    target = {
        commands: [
          ['==', ['get',['$reserved','this'],'width'],    ['get',['$reserved','this'],'x']]
          ['==', ['get',['$reserved','this'],'x'],        ['get',['$reserved','this'],'y']]
        ]
      }
    
    parse """
            ::[width] == ::this[x] == &[y]
          """
        , target
        
    parse """
            /* parans ignored */
            (::)[width] == (::this)[x] == (&)[y]
          """
        , target
    


  # Virtual Elements
  # ====================================================================

  describe '/ "Virtual Elements" /', ->

    parse """
            @virtual "Zone";
          """
        ,
          {
            commands: [
              ['virtual','Zone']
            ]
          }


    parse """
            "Zone"[width] == 100;
          """
        ,
          {
            commands: [
              ['==', ['get',['$virtual','Zone'],'width'],100]
            ]
          }

    parse """
            "A"[left] == "1"[top];
          """
        ,
          {
            commands: [
              ['==', ['get',['$virtual','A'],'x'],['get',['$virtual','1'],'y']]
            ]
          }

    parse '"box"[right] == "box2"[left];',
          {
            commands: [
              ['==', ['get',['$virtual','box'],'right'],['get',['$virtual','box2'],'x']]
            ]
          }



  # Adv Selectors
  # ====================================================================

  describe '/* Advanced Selectors */', ->

    parse """
            (html #main .boxes)[width] == 100
          """
        ,
          {
            commands: [
              ['==',
                [
                  'get',                  
                  [
                     "$class",
                     [
                        "$combinator",
                        [
                           "$id",
                           [
                              "$combinator",
                              [
                                 "$tag",
                                 "html"
                              ],
                              " "
                           ],
                           "main"
                        ],
                        " "
                     ],
                     "boxes"
                  ],
                  'width',
                ], 
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
              ['==', 
                [
                  'get',                  
                  [
                     "$attribute",
                     [
                        "$class",
                        [
                           "$combinator",
                           [
                              "$pseudo",
                              [
                                 "$id",
                                 [
                                    "$combinator",
                                    [
                                       "$tag",
                                       "*"
                                    ],
                                    " "
                                 ],
                                 "main"
                              ],
                              "not",
                              ".disabled"
                           ],
                           " "
                        ],
                        "boxes"
                     ],
                     "data-target",
                  ],
                  'width',
                ], 
                100
              ]
            ]
          }

    
    parse """
            (header !> h2.gizoogle ! section div:get('parentNode'))[target-size] == 100
          """
        ,
          {
            commands: [
              [
                '==', 
                [
                  'get',                  
                  ['$pseudo',
                    ['$tag',
                      ['$combinator', 
                        ['$tag', 
                          ['$combinator', 
                            ['$class',
                              ['$tag', 
                                ['$combinator', 
                                  ['$tag', 
                                    'header']
                                  '!>']
                                'h2']
                              'gizoogle']
                            '!']
                          'section']
                        ' '] 
                      'div']
                    'get', "'parentNode'"],
                  'target-size',
                ], 
                100
              ]
            ]
          }
    
    parse """
            (&.featured)[width] == 100;
          """
        ,
          {
            commands: [
              ['==', 
                ['get',['$class',['$reserved','this'],'featured'],'width'], 
                100
              ]
            ]
          }
          
    parse """
            (&"column2")[width] == 100;
          """
        ,
          {
            commands: [
              ['==', 
                ['get',['$virtual',['$reserved','this'],'column2'],'width'], 
                100
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
                ['get',['$attribute','~=','foo','"bar"'],'x'] 
                ['get',['$attribute','!=','foo','"bar"'],'x']
              ]
              ['==', 
                ['get',['$attribute','$=','foo','"bar"'],'x'] 
                ['get',['$attribute','*=','foo','"bar"'],'x']
              ]
              ['==', 
                ['get',['$attribute','^=','foo','"bar"'],'x'] 
                ['get',['$attribute','=','foo','"bar"'],'x']
              ]
            ]
          }

    parse """
            (::parent[disabled] ~ li:first)[width] == 100
          """
        ,
          {
            commands: [
              ['==', 
                [
                  'get',                  
                  [
                     "$pseudo",
                     [
                        "$tag",
                        [
                           "$combinator",
                           [
                              "$attribute",
                              [
                                 "$reserved",
                                 "parent"
                              ],
                              "disabled"
                           ],
                           "~"
                        ],
                        "li"
                     ],
                     "first"
                    ],
                  'width',
                ], 
                100
              ]
            ]
          }
    
    # comma seperated
    
    target = {
            commands: [
              ['==', 
                [
                  'get',                  
                  [
                     ",",
                     ["$virtual",["$reserved","this"],"grid"],
                     ["$virtual",["$class","that"],"grid"]
                     ["$class","box"]
                     ["$class","thing"]
                  ],
                  'width',
                ], 
                100
              ]
            ]
          }
    
    parse """
            (&"grid", .that"grid" , .box ,.thing)[width] == 100
          """
        ,
          target
    
    parse """
            (
              &"grid"
              , 
              .that"grid" , 
              .box,.thing
            )[width] == 100
          """
        ,
          target
          
  
  
  
  # Inline Statements
  # ====================================================================

  describe "/* inline statements */", ->

    parse """
            x: == 100;
          """
        ,
          {
            commands: [
              ['==',['get',['$reserved','this'],'x'],100]
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
                ['get',['$reserved','this'],'x']
                ['get',['$reserved','this'],'y']
              ]
              ['set','y','100px']
              ['>=',
                ['get',['$reserved','this'],'z']
                ['get',['$reserved','this'],'y']
              ]
            ]
          }
  
  
  # Rulesets
  # ====================================================================

  describe "/* Rulesets */", ->

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
                ['$class',['$id','box'],'class']
                [
                  ['set','color','blue']
                  ['==',['get',['$reserved','this'],'x'],100]                  
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
                ["$tag",["$combinator",['$class',['$tag','article'],'featured'],">"],"img"]                
                [
                  ['set','color','black']
                  ['rule',
                    ['$virtual',['$class','bg'],'face']
                    [
                      ['==',
                        ['get',['$reserved','this'],'x']
                        ['get','y']
                      ]
                    ]
                  ]
                  ['set','color','black']
                ]
              ]
            ]
          }
  
  
  # Directives
  # ====================================================================

  describe "/* Directives */", ->

    parse """
          @my-custom-directive blah blah blah {            
            color: blue;
          }
          """
        ,
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
  
  
  # If Else
  # ====================================================================

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
                ['==', ['get',['$id','box'],'right'], ['get',['$id','box2'],'x']]
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
                  ['!=', ['get',['$id','box'],'right'], ['get',['$id','box2'],'x'    ]],
                  ['<=', ['get',['$id','box'],'width'], ['get',['$id','box2'],'width']]
                ]
                []
              ]
            ]
          }
    
    
    conditionCommands = [
        "&&"
        ['!=', ['get',['$id','box'],'right'], ['get',['$id','box2'],'x']],
        ["||"
          ['<=', ['get',['$id','box'],'width'], ['get',['$id','box2'],'width']],
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
          
  
  
  # Stays
  # ====================================================================

  describe "/* Stays */", ->

    parse """
            @-gss-stay #box[width], [grid-height];
          """
        ,
          {
            commands: [
              ['stay',['get',['$id','box'],'width'],['get','grid-height']]
            ]
          }
    parse """
            @stay #box[width], [grid-height];
          """
        ,
          {
            commands: [
              ['stay',['get',['$id','box'],'width'],['get','grid-height']]
            ]
          }

    


  # JS Shit... WIP
  # ====================================================================

  describe '/ js layout hooks /', ->

    parse """
            [left-col] == [col-left];
            @for-each .box ```
            function (el,exp,engine) {
              var asts =[];
              asts.push();
            }
            ```;
          """
        ,
          {
            commands: [

              ['==', ['get', 'left-col'], ['get', 'col-left']]
              [
                'for-each',
                ['$class', 'box'],
                ['js',"""function (el,exp,engine) {
                    var asts =[];
                    asts.push();
                  }""" ]
              ]
            ]
          }

    parse """
            @for-all .box ```
            function (query,engine) {
              var asts =[];
              asts.push();
            }
            ```;
          """
        ,
          {
            commands: [
              [
                'for-all',
                ['$class', 'box'],
                ['js',"""function (query,engine) {
                    var asts =[];
                    asts.push();
                  }""" ]
              ]
            ]
          }


  # Chains... WIP
  # ====================================================================

  describe '/ @chain /', ->

    parse """
            @chain .box bottom(==)top;
          """
        ,
          {
            commands: [
              [
                'chain',
                ['$class', 'box'],
                ['eq-chain','bottom','top']
              ]
            ]
          }


    parse """
            @chain .box width();
          """
        ,
          {
            commands: [
              [
                'chain',
                ['$class', 'box'],
                ['eq-chain','width','width']
              ]
            ]
          }

    parse """
            @chain .box width() height(>=10>=) bottom(<=)top;
          """
        ,
          {
            commands: [
              [
                'chain',
                ['$class', 'box'],
                ['eq-chain','width','width'],
                ['gte-chain','height',10],
                ['gte-chain',10,'height'],
                ['lte-chain','bottom','top']
              ]
            ]
          }

    parse """
            @chain .box width([hgap]*2);
          """
        ,
          {
            commands: [
              [
                'chain',
                ['$class', 'box'],
                ['eq-chain','width',['*',['get','hgap'],2]]
                ['eq-chain',['*',['get','hgap'],2],'width']
              ]
            ]
          }

    parse """
            @chain .box width(+[hgap]*2);
          """
        ,
          {
            commands: [
              [
                'chain',
                ['$class', 'box'],
                ['eq-chain',['plus-chain','width',['*',['get','hgap'],2]],'width']
              ]
            ]
          }

    parse """
            @chain .box right(+10==)left;
          """
        ,
          {
            commands: [
              [
                'chain',
                ['$class', 'box'],
                ['eq-chain',['plus-chain','right',10],'left']
              ]
            ]
          }

    parse """
            @chain .box bottom(==!require)top;
          """
        ,
          {
            commands: [
              [
                'chain',
                ['$class', 'box'],
                ['eq-chain','bottom','top','require']
              ]
            ]
          }


    parse """
            @chain .box bottom(==!require)top width() height(!weak);
          """
        ,
          {
            commands: [
              [
                'chain',
                ['$class', 'box'],
                ['eq-chain','bottom','top',   'require']
                ['eq-chain','width', 'width']
                ['eq-chain','height','height',  'weak']
              ]
            ]
          }



    ### Not valid in parser at this stage
    parse """
            @chain .box height(==2+)center-x;
          """
        ,
          {
            commands: [
              [
                'chain',
                ['$class', 'box'],
                ['eq-chain','height',['multiply-chain',2,'center-x']]
              ]
            ]
          }
    ###


    ###
    parse """
            @chain .box width() {
              :first[width] == :last[width];
              :3rd[height] >= 2*:4th[height];
            };
          """
        ,
          {
            commands: [
              ['chain', ['$class', 'box'], ['eq-chain','width','width']]
              ['var', '.box:first[width]', 'width', ['$contextual',':first',['$class', 'box']]]
              ['==',['get','.box:first[width]'],['get','.box:last[width]']]
              ['var', '.box:first[width]', 'width', ['$contextual',':first',['$class', 'box']]]
            ]
          }
    ###
  
  
  # Prop Normalization
  # ====================================================================

  describe "/* Normalize Prop Names */", ->

    parse """
            #b[left] == [left];
            [left-col] == [col-left];
          """
        ,
          {
            commands: [
              ['==', ['get', ['$id', 'b'], 'x'], ['get', 'left']]
              ['==', ['get', 'left-col'], ['get', 'col-left']]
            ]
          }
    parse """
            #b[top] == [top];
          """
        ,
          {
            commands: [
              ['==',['get',['$id','b'],'y'],['get','top']]
            ]
          }

    parse """
            [right] == ::window[right];
          """
        ,
          {
            commands: [
              ['==',['get','right'],['get',['$reserved','window'],'width']]
            ]
          }
    parse """
            [left] == ::window[left];
          """
        ,
          {
            commands: [
              ['==', ['get','left'], ['get',['$reserved','window'],'x']]
            ]
          }
    parse """
            [top] == ::window[top];
          """
        ,
          {
            commands: [
              ['==', ['get', 'top'], ['get',['$reserved','window'],'y']]
            ]
          }
    parse """
            [bottom] == ::window[bottom];
          """
        ,
          {
            commands: [
              ['==', ['get','bottom'], ['get',['$reserved','window'],'height']]
            ]
          }

    parse """
            #b[cx] == [cx];
          """
        ,
          {
            commands: [
              ['==', ['get',['$id', 'b'],'center-x'], ['get', 'cx']]
            ]
          }
    parse """
            #b[cy] == [cy];
          """
        ,
          {
            commands: [
              ['==', ['get',['$id', 'b'],'center-y'], ['get', 'cy']]
            ]
          }
  
  

  # 2D
  # ====================================================================

  describe '/* 2D */', ->

    parse """
            #box1[size] == #box2[size];
          """
        ,
          {
            commands: [
              ['==', ['get', ['$id', 'box1'], 'width' ], ['get', ['$id', 'box2'], 'width' ]]
              ['==', ['get', ['$id', 'box1'], 'height'], ['get', ['$id', 'box2'], 'height']]
            ]
          }

    parse """
            #box1[position] == #box2[position];
          """
        ,
          {
            commands: [
              ['==', ['get', ['$id', 'box1'], 'x'], ['get', ['$id', 'box2'], 'x']]
              ['==', ['get', ['$id', 'box1'], 'y'], ['get', ['$id', 'box2'], 'y']]
            ]
          }

    parse """
            #box1[top-right] == #box2[center];
          """
        ,
          {
            commands: [
              ['==', ['get', ['$id', 'box1'], 'right'], ['get', ['$id', 'box2'], 'center-x']]
              ['==', ['get', ['$id', 'box1'], 'top'  ], ['get', ['$id', 'box2'], 'center-y']]
            ]
          }

    parse """
            #box1[bottom-right] == #box2[center];
          """
        ,
          {
            commands: [
              ['==', ['get', ['$id', 'box1'], 'right' ], ['get', ['$id', 'box2'], 'center-x']]
              ['==', ['get', ['$id', 'box1'], 'bottom'], ['get', ['$id', 'box2'], 'center-y']]
            ]
          }

    parse """
            #box1[bottom-left] == #box2[center];
          """
        ,
          {
            commands: [
              ['==', ['get', ['$id', 'box1'], 'left'  ], ['get', ['$id', 'box2'], 'center-x']]
              ['==', ['get', ['$id', 'box1'], 'bottom'], ['get', ['$id', 'box2'], 'center-y']]
            ]
          }

    parse """
            #box1[top-left] == #box2[center];
          """
        ,
          {
            commands: [
              ['==', ['get', ['$id', 'box1'], 'left'], ['get', ['$id', 'box2'], 'center-x']]
              ['==', ['get', ['$id', 'box1'], 'top' ], ['get', ['$id', 'box2'], 'center-y']]
            ]
          }

    parse """
            #box1[size] == #box2[intrinsic-size];
          """
        ,
          {
            commands: [
              ['==', ['get', ['$id', 'box1'], 'width' ], ['get', ['$id', 'box2'], 'intrinsic-width' ]]
              ['==', ['get', ['$id', 'box1'], 'height'], ['get', ['$id', 'box2'], 'intrinsic-height']]
            ]
          }

    parse """
            #box1[top-left] == #box2[bottom-right];
          """
        ,
          {
            commands: [
              ['==', ['get', ['$id', 'box1'], 'left'], ['get', ['$id', 'box2'], 'right' ]]
              ['==', ['get', ['$id', 'box1'], 'top' ], ['get', ['$id', 'box2'], 'bottom']]
            ]
          }

    parse """
            #box1[size] == #box2[width];
          """
        ,
          {
            commands: [
              ['==', ['get', ['$id', 'box1'], 'width' ], ['get', ['$id', 'box2'], 'width']]
              ['==', ['get', ['$id', 'box1'], 'height'], ['get', ['$id', 'box2'], 'width']]
            ]
          }

    parse """
            #box1[size] == #box2[height];
          """
        ,
          {
            commands: [
              ['==', ['get', ['$id', 'box1'], 'width' ], ['get', ['$id', 'box2'], 'height']]
              ['==', ['get', ['$id', 'box1'], 'height'], ['get', ['$id', 'box2'], 'height']]
            ]
          }

    parse """
            #box1[width] == #box2[size];
          """
        ,
          {
            commands: [
              ['==', ['get', ['$id', 'box1'], 'width'], ['get', ['$id', 'box2'], 'width' ]]
              ['==', ['get', ['$id', 'box1'], 'width'], ['get', ['$id', 'box2'], 'height']]
            ]
          }

    parse """
            #box1[height] == #box2[size];
          """
        ,
          {
            commands: [
              ['==', ['get', ['$id', 'box1'], 'height'], ['get', ['$id', 'box2'], 'width' ]]
              ['==', ['get', ['$id', 'box1'], 'height'], ['get', ['$id', 'box2'], 'height']]
            ]
          }

    parse """
            @-gss-stay #box[size];
          """
        ,
          {

            commands: [
              ['stay', ['get', ['$id','box'], 'width' ]]
              ['stay', ['get', ['$id','box'], 'height']]
            ]
          }

    parse """
            #box[size] == 100; // 2D var == number
          """
        ,
          {
            commands: [
              ['==', ['get', ['$id', 'box'], 'width' ], 100]
              ['==', ['get', ['$id', 'box'], 'height'], 100]
            ]
          }

    parse """
            [square-size] ==  100;
            #box[size] == [square-size]; // 2D var == var
          """
        ,
          {
            commands: [
              ['==', ['get', 'square-size'], 100]
              ['==', ['get', ['$id', 'box'], 'width' ], ['get', 'square-size']]
              ['==', ['get', ['$id', 'box'], 'height'], ['get', 'square-size']]
            ]
          }

    parse """
            #box[$square-size] ==  100;
            #box[size] == #box[$square-size]; // 2Dvar == element var
          """
        ,
          {
            commands: [
              ['==', ['get', ['$id', 'box'], '$square-size'], 100]
              ['==', ['get', ['$id', 'box'], 'width'       ], ['get', ['$id', 'box'], '$square-size']]
              ['==', ['get', ['$id', 'box'], 'height'      ], ['get', ['$id', 'box'], '$square-size']]
            ]
          }

  # Numbers
  # ====================================================================

  describe '/* Numbers */', ->
  
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
  
  
  
  # Units
  # ====================================================================

  describe '/* Units */', ->
  
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
  
  
  
  # Parans
  # ====================================================================  
  
  describe '/* Parans */', ->        
    
    
    parse """
            /* paran craziness */
            ((((#box1)[width]) + (("area")[width]))) == ((((#box2)[width]) + ((::window)[width])));
          """
        ,
          {
            commands: [
              ['==', 
                ['+',['get', ['$id', 'box1'], 'width'], ['get', ['$virtual', 'area'   ], 'width']], 
                ['+',['get', ['$id', 'box2'], 'width'], ['get', ['$reserved', 'window'], 'width']], 
              ]
            ]
          }
    
    #parse """
    #        /* 2D expressions w/ paran craziness */
    #        ((((#box1)[size]) + (("area")[size]))) == ((((#box2)[size]) + ((::window)[size])));
    #      """
    #    ,
    #      {
    #        commands: [
    #          ['==', 
    #            ['+',['get', 'width', ['$id', 'box1']], ['get', 'width', ['$virtual', 'area']]], 
    #            ['+',['get', 'width', ['$id', 'box2']], ['get', 'width', ['$reserved', 'window']]], 
    #          ],
    #          ['==', 
    #            ['+',['get', 'height', ['$id', 'box1']], ['get', 'height', ['$virtual', 'area']]], 
    #            ['+',['get', 'height', ['$id', 'box2']], ['get', 'height', ['$reserved', 'window']]], 
    #          ]
    #        ]
    #      }
    
    
  
  
  
  
  # Plugins
  # ====================================================================  
  
  describe '/* API Hooks */', ->        
    
    
    parse """
            @h [#left][#right] !strong {}
          """
        ,
          {
            commands: [
              ['==',['get',['$id','left'],'right'],['get',['$id','right'],'x'],'strong']
            ]
          }
    
    parse """
            @v [#top][#bottom] !strong;
          """
        ,
          {
            commands: [
              ['==',['get',['$id','top'],'bottom'],['get',['$id','bottom'],'y'],'strong']
            ]
          }