# 2D Unpacker
# =====================================================
#
# Unpack 2D properties from the AST.
#
# Example: size becomes width and height.
#
# Takes a GSS command array, or AST, search for
# 2D properties and expand them.

module.exports = (ast) ->
    buffer = []
    analyze ast, buffer
    expand2dProperties buffer
    #JSON.parse JSON.stringify ast
    ast

analyze = (ast, buffer) ->
  if ast.commands?
    for node in ast.commands
      _analyze node, ast.commands, true, buffer

_analyze = (node, commands, firstLevelCmd, buffer) =>
  if node.length >= 3
    #Is it a parent node?
    commandName = node[0]
    headNode = node[1]
    tailNode = node[2]

    if commandName == 'rule'
      _unpackRuleset2dConstraints node, tailNode, commands, buffer
    else
      _traverseAstFor2DProperties node, headNode, commands, buffer, true
      _analyzeTailAstFor2DProperty node, tailNode, commands, buffer

      if !node._has2dProperty
        node._has2dProperty = headNode._has2dProperty or tailNode._has2dProperty

      if firstLevelCmd and node._has2dProperty
        _addConstraintForUnpacking commands, node, buffer

  if node.length == 2 and node[0] == 'stay'
    _unpackStay2dConstraint node, commands, buffer, firstLevelCmd

_unpackRuleset2dConstraints = (node, tailNode, commands, buffer) =>
  for subCommand, i in tailNode[0..node.length]
    if subCommand instanceof Array
      _analyze subCommand, commands, false, buffer

      if subCommand._has2dProperty
        _addConstraintForUnpacking tailNode, subCommand, buffer

_unpackStay2dConstraint = (node, commands, buffer, firstLevelCmd) =>
  stayConstraint = node[1]
  _analyze stayConstraint, commands, false, buffer
  if stayConstraint._has2dProperty?
    #Stays don't have tail node.
    node._has2dProperty = stayConstraint._has2dProperty
    node._2DPropertyName = stayConstraint._2DPropertyName
    node._has2dHeadNode = stayConstraint._has2dProperty

  if firstLevelCmd and node._has2dProperty
    _addConstraintForUnpacking commands, node, buffer

# Ultimately the 2D property will always be in the tail of an AST node.
_analyzeTailAstFor2DProperty = (parentNode, node, commands, buffer) =>
  if node not instanceof Array
    if propertyMapping[node]?
      parentNode._has2dProperty = true
      parentNode._2DPropertyName = node
  else
    _traverseAstFor2DProperties parentNode, node, commands, buffer

_traverseAstFor2DProperties = (parentNode, node, commands, buffer, isHeadConstraint) =>
  if node instanceof Array
    _analyze node, commands, false, buffer
    if node._has2dProperty?
      parentNode._has2dHeadNode = node._has2dProperty if isHeadConstraint
      parentNode._has2dTailNode = node._has2dProperty if not isHeadConstraint

_addConstraintForUnpacking = (commands, node, buffer) =>
      buffer.push
        toExpand:
          parent: commands
          nodeWith2DProp: node

expand2dProperties = (buffer) ->
  for expandNode in buffer
    clonedConstraint = _clone expandNode.toExpand.nodeWith2DProp
    #insert in the commands by respecting the order of the constraints
    insertionIndex = (expandNode.toExpand.parent.indexOf expandNode.toExpand.nodeWith2DProp) + 1
    expandNode.toExpand.parent.splice insertionIndex, 0, clonedConstraint

    _routeTraversalFor2DExpansion expandNode.toExpand.nodeWith2DProp, 0
    _routeTraversalFor2DExpansion clonedConstraint, 1

_routeTraversalFor2DExpansion = (node, index1DPropertyName) ->
  if node._has2dHeadNode? and node._has2dHeadNode
    _changePropertyName node[1], index1DPropertyName
  if node._has2dTailNode? and node._has2dTailNode
    _changePropertyName node[2], index1DPropertyName

_changePropertyName = (node, onedPropIndex) =>
  if node instanceof Array and node.length == 3
    if node[2] == node._2DPropertyName
      node[2] = propertyMapping[node._2DPropertyName][onedPropIndex]
    else
      _routeTraversalFor2DExpansion node, onedPropIndex

_clone = (obj) ->
  return obj  if obj is null or typeof (obj) isnt "object"
  temp = new obj.constructor()
  for key of obj
    temp[key] = _clone(obj[key])
  temp

propertyMapping =
  'bottom-left'   : ['left', 'bottom']
  'bottom-right'  : ['right', 'bottom']
  center          : ['center-x', 'center-y']
  'intrinsic-size': ['intrinsic-width', 'intrinsic-height']
  position        : ['x', 'y']
  size            : ['width', 'height']
  'top-left'      : ['left', 'top']
  'top-right'     : ['right', 'top']
