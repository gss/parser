# 2D Unpacker
# =====================================================
# Unpack 2D properties from the AST.
# Example: size becomes width and height.
#
# Takes a GSS command array, or AST, search for
# 2D properties and expand them by duplicating in the commands
# the AST representing the constraint using 2d props.

module.exports = (ast) ->
  buffer = []
  buffer2dExpansion ast, buffer
  expandConstraintsWith2dProperties buffer
  ast

buffer2dExpansion = (ast, buffer) ->
  if ast.commands?
    for node in ast.commands
      _buffer2dExpansion node, ast.commands, buffer

_buffer2dExpansion = (node, commands, buffer) =>
  if node.length > 1
    if node[0] == 'rule'
      _unpackRuleset2dConstraints node, node[2], buffer
    else
      for childNode, i in node[1..node.length]
        if _traverseAstFor2DProperties childNode
          if commands then buffer.push { toExpand: { commands: commands, constraint: node }}
          return true
  return false

_unpackRuleset2dConstraints = (node, commands, buffer) =>
  for constraint, i in commands[0..node.length]
      _buffer2dExpansion constraint, commands, buffer

_traverseAstFor2DProperties = (node) =>
  if node instanceof Array and node.length > 0
    if node[node.length - 1] not instanceof Array and propertyMapping[node[node.length - 1]]?
      return true
    else
      return _buffer2dExpansion node
  return false

expandConstraintsWith2dProperties = (buffer) ->
  for expansionItem in buffer
    clonedConstraint = _clone expansionItem.toExpand.constraint
    #insert in the commands by respecting the order of the constraints
    insertionIndex = 1 + (expansionItem.toExpand.commands.indexOf expansionItem.toExpand.constraint)
    expansionItem.toExpand.commands.splice insertionIndex, 0, clonedConstraint

    _rename2dTo1dProperty expansionItem.toExpand.constraint, 0
    _rename2dTo1dProperty clonedConstraint, 1

_rename2dTo1dProperty = (node, index1DPropertyName) ->
  for subNode, i in node[1..node.length]
    if subNode instanceof Array
      if propertyMapping[subNode[subNode.length - 1]]
        #replace 2d by 1d property name
        subNode[subNode.length - 1] = propertyMapping[subNode[subNode.length - 1]][index1DPropertyName]
      else
        _rename2dTo1dProperty subNode, index1DPropertyName

_clone = (obj) ->
  JSON.parse JSON.stringify obj

propertyMapping =
  'bottom-left'   : ['left', 'bottom']
  'bottom-right'  : ['right', 'bottom']
  center          : ['center-x', 'center-y']
  'intrinsic-size': ['intrinsic-width', 'intrinsic-height']
  position        : ['x', 'y']
  size            : ['width', 'height']
  'top-left'      : ['left', 'top']
  'top-right'     : ['right', 'top']
