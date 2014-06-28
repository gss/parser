if window?
  parser = require 'ccss-compiler'
else
  chai = require 'chai' unless chai
  parser = require '../lib/compiler'

{expect} = chai


parse = (source, expectation, pending) ->
  itFn = if pending then xit else it

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
              ['lte', ['number', 10], ['number', 2]]
              ['eq', ['number', 2], ['number', 3]]
              ['lt', ['number', 3], ['number', 4]]
              ['eq', ['number', 4], ['number', 5]]
            ]
          }

    parse """
            [md-width] == ([width] * 2 - [gap] * 2) / 4 + 10 !require; // order of operations
          """
        ,
          {
            commands: [
              ['eq',
                ['get', 'md-width'],
                ['plus'
                  [ 'divide',
                    ['minus',
                      ['multiply',
                        ['get','width'],
                        ['number',2]
                      ],
                      ['multiply',
                        ['get','gap'],
                        ['number',2]
                      ]
                    ],
                    ['number',4]
                  ],
                  ['number',10]
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
              ['lte', [
                'multiply', ['get', 'grid-height'], ['get$', 'width', ['$id', 'box2']]
                ],
                ['number', 2]
              ]
              ['eq', ['number', 2], ['number', 3]]
              ['lt', ['number', 3], ['number', 4]]
              ['eq', ['number', 4], ['number', 5]]
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
              ['eq', ['number', 4], ['number', 5], 'strong', 10]
              ['eq', ['number', 5], ['number', 6], 'strong', 10]
            ]
          }

    expectError '[a] == [b] !stron', 'Invalid Strength or Weight'
    expectError '[a] == [b] !strong0.5'



  # Pseudos
  # ====================================================================

  describe '/* Reserved Pseudos */', ->

    parse """
            ::[width] == ::parent[width]
          """
        ,
          {
            commands: [
              ['eq', ['get$','width',['$reserved','this']], ['get$','width',['$reserved', 'parent']]]
            ]
          }

    # viewport gets normalized to window
    parse """
            ::scope[width] == ::this[width] == ::document[width] == ::viewport[width] == ::window[height]
          """
        ,
          {
            commands: [
              ['eq', ['get$','width',['$reserved','scope']],    ['get$','width',['$reserved','this']]]
              ['eq', ['get$','width',['$reserved','this']],     ['get$','width',['$reserved','document']]]
              ['eq', ['get$','width',['$reserved','document']], ['get$','width',['$reserved','window']]]
              ['eq', ['get$','width',['$reserved','window']],   ['get$','height',['$reserved','window']]]
            ]
          }
    
    # normalize ::this selector
    
    target = {
        commands: [
          ['eq', ['get$','width',['$reserved','this']],    ['get$','x',['$reserved','this']]]
          ['eq', ['get$','x',['$reserved','this']],        ['get$','y',['$reserved','this']]]
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
              ['eq', ['get$','width',['$virtual','Zone']], ['number',100]]
            ]
          }

    parse """
            "A"[left] == "1"[top];
          """
        ,
          {
            commands: [
              ['eq', ['get$','x',['$virtual','A']],['get$','y',['$virtual','1']]]
            ]
          }

    parse '"box"[right] == "box2"[left];',
          {
            commands: [
              ['eq', ['get$','right',['$virtual','box']],['get$','x',['$virtual','box2']]]
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
              ['eq',
                [
                  'get$',
                  'width',
                  [
                     "$class",
                     [
                        "$combin",
                        [
                           "$id",
                           [
                              "$combin",
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
                  ]
                ], 
                ['number', 100]
              ]
            ]
          }

    parse """
            (html #main:not(.disabled) .boxes[data-target="true"])[width] == 100
          """
        ,
          {
            commands: [
              ['eq', 
                [
                  'get$',
                  'width',
                  [
                     "$attr",
                     [
                        "$class",
                        [
                           "$combin",
                           [
                              "$pseudo",
                              [
                                 "$id",
                                 [
                                    "$combin",
                                    [
                                       "$tag",
                                       "html"
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
                     "data-target=\"true\""
                  ]
                ], 
                ['number', 100]
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
                'eq', 
                [
                  'get$',
                  'target-size',
                  ['$pseudo',
                  ['$tag',
                    ['$combin', 
                      ['$tag', 
                        ['$combin', 
                          ['$class',
                            ['$tag', 
                              ['$combin', 
                                ['$tag', 
                                  'header']
                                '!>']
                              'h2']
                            'gizoogle']
                          '!']
                        'section']
                      ' '] 
                    'div']
                  'get', "'parentNode'"]
                ], 
                ['number', 100]
              ]
            ]
          }
    
    parse """
            (&.featured)[width] == 100;
          """
        ,
          {
            commands: [
              ['eq', 
                [
                  'get$',
                  'width',
                  ['$class',['$reserved','this'],'featured']
                ], 
                ['number', 100]
              ]
            ]
          }
          
    parse """
            (&"column2")[width] == 100;
          """
        ,
          {
            commands: [
              ['eq', 
                [
                  'get$',
                  'width',
                  ['$virtual',['$reserved','this'],'column2']
                ], 
                ['number', 100]
              ]
            ]
          }
    

    parse """
            (::parent[disabled] ~ li:first)[width] == 100
          """
        ,
          {
            commands: [
              ['eq', 
                [
                  'get$',
                  'width',
                  [
                     "$pseudo",
                     [
                        "$tag",
                        [
                           "$combin",
                           [
                              "$attr",
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
                  ]
                ], 
                ['number', 100]
              ]
            ]
          }
    
    # comma seperated
    
    target = {
            commands: [
              ['eq', 
                [
                  'get$',
                  'width',
                  [
                     ",",
                     ["$virtual",["$reserved","this"],"grid"],
                     ["$virtual",["$class","that"],"grid"]
                     ["$class","box"]
                     ["$class","thing"]
                  ]
                ], 
                ['number', 100]
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
              ['eq',
                ['get$','x',['$reserved','this']]
                ['number',100]
              ]
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
              ['lte',
                ['get$','x',['$reserved','this']]
                ['get$','y',['$reserved','this']]                
              ]
              ['set','y','100px']
              ['gte',
                ['get$','z',['$reserved','this']]
                ['get$','y',['$reserved','this']]                
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
                  ['eq',
                    ['get$','x',['$reserved','this']]
                    ['number',100]
                  ]                  
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
                ["$tag",["$combin",['$class',['$tag','article'],'featured'],">"],"img"]                
                [
                  ['set','color','black']
                  ['rule',
                    ['$virtual',['$class','bg'],'face']
                    [
                      ['eq',
                        ['get$','x',['$reserved','this']]
                        ['get','y']
                      ]
                    ]
                  ]
                  ['set','color','black']
                ]
              ]
            ]
          }
  
  
  # Rulesets
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
  
  
  # Stays
  # ====================================================================

  describe "/* Stays */", ->

    parse """
            @-gss-stay #box[width], [grid-height];
          """
        ,
          {
            commands: [
              ['stay',['get$','width',['$id','box']],['get','grid-height']]
            ]
          }
    parse """
            @stay #box[width], [grid-height];
          """
        ,
          {
            commands: [
              ['stay',['get$','width',['$id','box']],['get','grid-height']]
            ]
          }



  # Conditionals
  # ====================================================================

  describe '/ @? conditionals /', ->

    parse """
            @cond #box[right] == #box2[x];
          """
        ,
          {
            commands: [
              ['?==', ['get$','right',['$id','box']], ['get$','x',['$id','box2']]]
            ]
          }

    parse """
            @cond 2 * [right] == [x] + 100;
          """
        ,
          {
            commands: [
              ['?==',['multiply',['number',2],['get','right']], ['plus',['get','x'],['number',100]] ]
            ]
          }

    parse """
            @cond #box[right] != #box2[x] AND #box[width] <= #box2[width];
          """
        ,
          {
            commands: [
              ["&&"
                ['?!=', ['get$','right',['$id','box']], ['get$','x',['$id','box2']]],
                ['?<=', ['get$','width',['$id','box']], ['get$','width',['$id','box2']]]
              ]
            ]
          }

    parse """
            @cond (#box[right] != #box2[x]) AND (#box[width] <= #box2[width]);
          """
        ,
          {
            commands: [
              ["&&"
                ['?!=', ['get$','right',['$id','box']], ['get$','x',['$id','box2']]],
                ['?<=', ['get$','width',['$id','box']], ['get$','width',['$id','box2']]]
              ]
            ]
          }

    parse """
            @cond (#box[right] != #box2[x]) and (#box[width] <= #box2[width] or [x] == 100);
          """
        ,
          {
            commands: [
              ["&&"
                ['?!=', ['get$','right',['$id','box']], ['get$','x',['$id','box2']]],
                ["||"
                  ['?<=', ['get$','width',['$id','box']], ['get$','width',['$id','box2']]],
                  ['?==', ['get','x'],['number',100]]
                ]
              ]
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

              ['eq', ['get', 'left-col'], ['get', 'col-left']]
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
                ['gte-chain','height',['number',10]],
                ['gte-chain',['number',10],'height'],
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
                ['eq-chain','width',['multiply',['get','hgap'],['number',2]]]
                ['eq-chain',['multiply',['get','hgap'],['number',2]],'width']
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
                ['eq-chain',['plus-chain','width',['multiply',['get','hgap'],['number',2]]],'width']
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
                ['eq-chain',['plus-chain','right',['number',10]],'left']
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
                ['eq-chain','height',['multiply-chain',['number',2],'center-x']]
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
              ['eq',['get','.box:first[width]'],['get','.box:last[width]']]
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
              ['eq', ['get$', 'x', ['$id', 'b']], ['get', 'left']]
              ['eq', ['get', 'left-col'], ['get', 'col-left']]
            ]
          }
    parse """
            #b[top] == [top];
          """
        ,
          {
            commands: [
              ['eq',['get$','y',['$id','b']],['get','top']]
            ]
          }

    parse """
            [right] == ::window[right];
          """
        ,
          {
            commands: [
              ['eq',['get','right'],['get$','width',['$reserved','window']]]
            ]
          }
    parse """
            [left] == ::window[left];
          """
        ,
          {
            commands: [
              ['eq', ['get','left'], ['get$','x',['$reserved','window']]]
            ]
          }
    parse """
            [top] == ::window[top];
          """
        ,
          {
            commands: [
              ['eq', ['get', 'top'], ['get$','y',['$reserved','window']]]
            ]
          }
    parse """
            [bottom] == ::window[bottom];
          """
        ,
          {
            commands: [
              ['eq', ['get','bottom'], ['get$','height',['$reserved','window']]]
            ]
          }

    parse """
            #b[cx] == [cx];
          """
        ,
          {
            commands: [
              ['eq', ['get$', 'center-x',['$id', 'b']], ['get', 'cx']]
            ]
          }
    parse """
            #b[cy] == [cy];
          """
        ,
          {
            commands: [
              ['eq', ['get$','center-y',['$id', 'b']], ['get', 'cy']]
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
              ['eq', ['get$', 'width', ['$id', 'box1']], ['get$', 'width', ['$id', 'box2']]]
              ['eq', ['get$', 'height', ['$id', 'box1']], ['get$', 'height', ['$id', 'box2']]]
            ]
          }

    parse """
            #box1[position] == #box2[position];
          """
        ,
          {
            commands: [
              ['eq', ['get$', 'x', ['$id', 'box1']], ['get$', 'x', ['$id', 'box2']]]
              ['eq', ['get$', 'y', ['$id', 'box1']], ['get$', 'y', ['$id', 'box2']]]
            ]
          }

    parse """
            #box1[top-right] == #box2[center];
          """
        ,
          {
            commands: [
              ['eq', ['get$', 'right', ['$id', 'box1']], ['get$', 'center-x', ['$id', 'box2']]]
              ['eq', ['get$', 'top', ['$id', 'box1']], ['get$', 'center-y', ['$id', 'box2']]]
            ]
          }

    parse """
            #box1[bottom-right] == #box2[center];
          """
        ,
          {
            commands: [
              ['eq', ['get$', 'right', ['$id', 'box1']], ['get$', 'center-x', ['$id', 'box2']]]
              ['eq', ['get$', 'bottom', ['$id', 'box1']], ['get$', 'center-y', ['$id', 'box2']]]
            ]
          }

    parse """
            #box1[bottom-left] == #box2[center];
          """
        ,
          {
            commands: [
              ['eq', ['get$', 'left', ['$id', 'box1']], ['get$', 'center-x', ['$id', 'box2']]]
              ['eq', ['get$', 'bottom', ['$id', 'box1']], ['get$', 'center-y', ['$id', 'box2']]]
            ]
          }

    parse """
            #box1[top-left] == #box2[center];
          """
        ,
          {
            commands: [
              ['eq', ['get$', 'left', ['$id', 'box1']], ['get$', 'center-x', ['$id', 'box2']]]
              ['eq', ['get$', 'top', ['$id', 'box1']], ['get$', 'center-y', ['$id', 'box2']]]
            ]
          }

    parse """
            #box1[size] == #box2[intrinsic-size];
          """
        ,
          {
            commands: [
              ['eq', ['get$', 'width', ['$id', 'box1']], ['get$', 'intrinsic-width', ['$id', 'box2']]]
              ['eq', ['get$', 'height', ['$id', 'box1']], ['get$', 'intrinsic-height', ['$id', 'box2']]]
            ]
          }

    parse """
            #box1[top-left] == #box2[bottom-right];
          """
        ,
          {
            commands: [
              ['eq', ['get$', 'left', ['$id', 'box1']], ['get$', 'right', ['$id', 'box2']]]
              ['eq', ['get$', 'top', ['$id', 'box1']], ['get$', 'bottom', ['$id', 'box2']]]
            ]
          }

    parse """
            #box1[size] == #box2[width];
          """
        ,
          {
            commands: [
              ['eq', ['get$', 'width', ['$id', 'box1']], ['get$', 'width', ['$id', 'box2']]]
              ['eq', ['get$', 'height', ['$id', 'box1']], ['get$', 'width', ['$id', 'box2']]]
            ]
          }

    parse """
            #box1[size] == #box2[height];
          """
        ,
          {
            commands: [
              ['eq', ['get$', 'width', ['$id', 'box1']], ['get$', 'height', ['$id', 'box2']]]
              ['eq', ['get$', 'height', ['$id', 'box1']], ['get$', 'height', ['$id', 'box2']]]
            ]
          }

    parse """
            #box1[width] == #box2[size];
          """
        ,
          {
            commands: [
              ['eq', ['get$', 'width', ['$id', 'box1']], ['get$', 'width', ['$id', 'box2']]]
              ['eq', ['get$', 'width', ['$id', 'box1']], ['get$', 'height', ['$id', 'box2']]]
            ]
          }

    parse """
            #box1[height] == #box2[size];
          """
        ,
          {
            commands: [
              ['eq', ['get$', 'height', ['$id', 'box1']], ['get$', 'width', ['$id', 'box2']]]
              ['eq', ['get$', 'height', ['$id', 'box1']], ['get$', 'height', ['$id', 'box2']]]
            ]
          }

    parse """
            @-gss-stay #box[size];
          """
        ,
          {

            commands: [
              ['stay', ['get$', 'width', ['$id','box']]]
              ['stay', ['get$', 'height', ['$id','box']]]
            ]
          }

    parse """
            #box[size] == 100; // 2D var == number
          """
        ,
          {
            commands: [
              ['eq', ['get$', 'width', ['$id', 'box']], ['number', 100]]
              ['eq', ['get$', 'height', ['$id', 'box']], ['number', 100]]
            ]
          }

    parse """
            [square-size] ==  100;
            #box[size] == [square-size]; // 2D var == var
          """
        ,
          {
            commands: [
              ['eq', ['get', 'square-size'], ['number', 100]]
              ['eq', ['get$', 'width', ['$id', 'box']], ['get', 'square-size']]
              ['eq', ['get$', 'height', ['$id', 'box']], ['get', 'square-size']]
            ]
          }

    parse """
            #box[$square-size] ==  100;
            #box[size] == #box[$square-size]; // 2Dvar == element var
          """
        ,
          {
            commands: [
              ['eq', ['get$', '$square-size', ['$id', 'box']], ['number', 100]]
              ['eq', ['get$', 'width', ['$id', 'box']], ['get$', '$square-size', ['$id', 'box']]]
              ['eq', ['get$', 'height', ['$id', 'box']], ['get$', '$square-size', ['$id', 'box']]]
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
                ['eq', ['get', 'left'], ['number', 0.4]]
              ]
            }

    parse """
            [left] == .4; // without leading zero
            [left] == .004;
          """
          ,
            {
              commands: [
                ['eq', ['get', 'left'], ['number', 0.4]]
                ['eq', ['get', 'left'], ['number', 0.004]]
              ]
            }

    parse """
            [left] == 0 - 1; // negative via additive expression
          """
          ,
            {
              commands: [
                ['eq', ['get', 'left'], ['minus', ['number', 0], ['number', 1]]]
              ]
            }

    parse """
            [left] == (0 - 1); // negative via additive expression with parentheses
          """
          ,
            {
              commands: [
                ['eq', ['get', 'left'], ['minus', ['number', 0], ['number', 1]]]
              ]
            }

    parse """
            [left] == 0-1; // negative via additive expression without spaces
          """
          ,
            {
              commands: [
                ['eq', ['get', 'left'], ['minus', ['number', 0], ['number', 1]]]
              ]
            }

    parse """
            [left] == -1; // negative without additive expression
          """
          ,
            {
              commands: [
                ['eq', ['get', 'left'], ['number', -1]]
              ]
            }

    parse """
            [left] == -0.4; // negative floating point with leading zero
          """
          ,
            {
              commands: [
                ['eq', ['get', 'left'], ['number', -0.4]]
              ]
            }

    parse """
            [left] == -.4; // negative floating point without leading zero
          """
          ,
            {
              commands: [
                ['eq', ['get', 'left'], ['number', -0.4]]
              ]
            }

    parse """
            [left] == 0 + 1; // positive via additive expression
          """
          ,
            {
              commands: [
                ['eq', ['get', 'left'], ['plus', ['number', 0], ['number', 1]]]
              ]
            }

    parse """
            [left] == (0 + 1); // positive via additive expression with parentheses
          """
          ,
            {
              commands: [
                ['eq', ['get', 'left'], ['plus', ['number', 0], ['number', 1]]]
              ]
            }

    parse """
            [left] == 0+1; // positive via additive expression without spaces
          """
          ,
            {
              commands: [
                ['eq', ['get', 'left'], ['plus', ['number', 0], ['number', 1]]]
              ]
            }

    parse """
            [left] == +1; // positive without additive expression
          """
          ,
            {
              commands: [
                ['eq', ['get', 'left'], ['number', 1]]
              ]
            }

    parse """
            [left] == +0.4; // positive floating point with leading zero
          """
          ,
            {
              commands: [
                ['eq', ['get', 'left'], ['number', 0.4]]
              ]
            }

    parse """
            [left] == +.4; // positive floating point without leading zero
          """
          ,
            {
              commands: [
                ['eq', ['get', 'left'], ['number', 0.4]]
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
                ['eq', ['px', 10], ['px', 0.4]]
                ['eq', ['px', -0.01], ['px', 0.01]]
              ]
            }
    
    parse """
            10em == 0.4em;
            -.01em == .01em;
          """
          ,
            {
              commands: [
                ['eq', ['em', 10], ['em', 0.4]]
                ['eq', ['em', -0.01], ['em', 0.01]]
              ]
            }
    
    parse """
            10% == 0.4%;
            -.01% == .01%;
          """
          ,
            {
              commands: [
                ['eq', ['%', 10], ['%', 0.4]]
                ['eq', ['%', -0.01], ['%', 0.01]]
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
              ['eq', 
                ['plus',['get$', 'width', ['$id', 'box1']], ['get$', 'width', ['$virtual', 'area']]], 
                ['plus',['get$', 'width', ['$id', 'box2']], ['get$', 'width', ['$reserved', 'window']]], 
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
    #          ['eq', 
    #            ['plus',['get$', 'width', ['$id', 'box1']], ['get$', 'width', ['$virtual', 'area']]], 
    #            ['plus',['get$', 'width', ['$id', 'box2']], ['get$', 'width', ['$reserved', 'window']]], 
    #          ],
    #          ['eq', 
    #            ['plus',['get$', 'height', ['$id', 'box1']], ['get$', 'height', ['$virtual', 'area']]], 
    #            ['plus',['get$', 'height', ['$id', 'box2']], ['get$', 'height', ['$reserved', 'window']]], 
    #          ]
    #        ]
    #      }