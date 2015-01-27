# Scoper
# =====================================================
#
# Effectively hoists vars & virtuals to
# highest parent scope used.
#
# Consistent with vars in CoffeeScript.
#
# Takes a GSS command array, or AST,
# and injects parent scope operators, `^`.

module.exports = (ast) ->
    buffer = [
      {
        _parentScope: undefined
        _childScopes: []
        _unscopedVars:[]
      }
    ]

    mapping =
      'bottom-left'   : ['left', 'bottom']
      'bottom-right'  : ['right', 'bottom']
      center          : ['center-x', 'center-y']
      'intrinsic-size': ['intrinsic-width', 'intrinsic-height']
      position        : ['x', 'y']
      size            : ['width', 'height']
      'top-left'      : ['left', 'top']
      'top-right'     : ['right', 'top']


    analyze ast, mapping
    #mutate buffer
    #JSON.parse JSON.stringify ast
    ast

propertyMapping =
  'bottom-left'   : ['left', 'bottom']
  'bottom-right'  : ['right', 'bottom']
  center          : ['center-x', 'center-y']
  'intrinsic-size': ['intrinsic-width', 'intrinsic-height']
  position        : ['x', 'y']
  size            : ['width', 'height']
  'top-left'      : ['left', 'top']
  'top-right'     : ['right', 'top']

contraintOperator = [
  '>='
  '<='
  '=='
]

analyze = (ast, mapping) ->
  if ast.commands?
    for node in ast.commands
      _analyze node, ast.commands, true

_analyze = (node, commands, firstLevelCmd) =>

  if node.length == 3

    #Is it a parent node?
    commandName = node[0]
    headNode = node[1]
    tailNode = node[2]
    clonedNode = null

    if commandName == 'rule'
      node.isParentNode = true
      headNode._parentNode = node
      tailnode._parentNode = node

    if headNode instanceof Array && headNode.length == 3
      headNode = _analyze headNode, commands, false

    if tailNode instanceof Array && tailNode.length == 3
      tailNode = _analyze tailNode, commands, false

    else if tailNode instanceof Array isnt true
      properties = propertyMapping[tailNode]

      if properties?
        node.is2dProperty = true

    if tailNode.is2dProperty? || headNode.is2dProperty?
      if node.isParentNode?
        #do some shit
      else if firstLevelCmd?
        clonedNode = _clone node
        commands.push clonedNode
        
    node

_clone = (obj) ->
  return obj  if obj is null or typeof (obj) isnt "object"
  temp = new obj.constructor()
  for key of obj
    temp[key] = _clone(obj[key])
  temp
