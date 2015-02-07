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


# Plugins
# ====================================================================

describe '/* Plugins */', ->
  
  describe '/* VFL */', ->
  
    parse """
            @v (#top)(#bottom) !strong;
          """
        ,
          {
            commands: [
              ['==',['get',['#','top'],'bottom'],['get',['#','bottom'],'y'],'strong']
            ]
          }

    parse """/* VFL empty ruleset */
            @h (#left)(#right) !strong {}
          """
        ,
          {
            commands: [
              ['==',['get',['#','left'],'right'],['get',['#','right'],'x'],'strong']
            ]
          }

    parse """/* VFL ruleset */
            @h (button.featured)-10-(#b2) {
              width: == 100;
              height: == &:next[height];
            }
          """
        ,
          {
            commands: [
              ['==',
                ['+', ['get',[['tag','button'], ['.','featured']],'right'], 10],
                ['get',['#','b2'],'x']
              ]
              ['rule',
                [',',
                  [['tag','button'], ['.','featured']]
                  ['#','b2']
                ],
                parser.parse("width: == 100; height: == &:next[height];").commands
              ]
            ]
          }


    parse """/* splatted VFL ruleset */
              @v |(.post)...| in(::window) {
                  border-radius: == 4;
                  @h |(&)| in(::window);
                  opacity: == .5;
                }

          """,
          {
            commands: [].concat(
                parser.parse("@v |(.post)...| in(::window);").commands
              ).concat (
                [['rule',
                  ['.','post'],
                  [].concat(
                    parser.parse("border-radius: == 4;").commands
                  ).concat(
                    parser.parse("@h |(&)| in(::window);").commands
                  ).concat(
                    parser.parse("opacity: == .5;").commands
                  )
                ]]
              )

          }

    parse "DO NOT special case how ::scope is prepended to rule selectors",
          """
            @h (&)(::scope .box)(.post)(::scope)(::this "fling")(.outie .innie)("virtual") {
                &[width] == 10;
              }
          """,
          {
            commands: [].concat(
                parser.parse('@h (&)(::scope .box)(.post)(::scope)(::this "fling")(.outie .innie)("virtual");').commands
              ).concat(parser.parse("""
                ::this, ::scope .box, .post, ::scope, ::this "fling", .outie .innie, "virtual" {
                  width: == 10;
                }
              """).commands)
          }

    parse """
              /* VFL w/ ruleset + CCSS */
            
              @v |
                  -10-
                  (#cover)
                in(#profile-card);

              #follow[center-x] == #profile-card[center-x];

              @h |-10-(#message)
                in(#profile-card) {
                  &[top] == &:next[top];
                }

              #follow[center-y] == #profile-card[center-y];

          """,
          {
            commands: [].concat(
                parser.parse("@v |-10-(#cover) in(#profile-card);").commands
              ).concat (
                parser.parse("#follow[center-x] == #profile-card[center-x];").commands
              ).concat (
                parser.parse("""@h |-10-(#message)
                in(#profile-card) {
                  &[top] == &:next[top];
                }""").commands
              ).concat (
                parser.parse("#follow[center-y] == #profile-card[center-y];").commands
              )

          }