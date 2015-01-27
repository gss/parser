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

  describe "inline 2d property on one side of the constraint", ->

    twoDimensionsMappingTest 'hoist 1 level root before',
        commands:
          [
            ['==', ['get', ['#', 'div'], 'size'], 100]
          ]
      ,
        commands:
          [
            ['==', ['get', ['#', 'div'], 'size'], 100]
            ['==', ['get', ['#', 'div'], 'size'], 100]
          ]
