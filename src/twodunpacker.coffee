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
    ast

analyze = (ast, buffer) ->
  if ast.commands?
    for node in ast.commands
      _analyze node, ast.commands, true, buffer

_analyze = (node, commands, firstLevelCmd, buffer) =>

  if node.length >= 2
    commandName = node[0]
    headNode = node[1]
    tailNode = node[2] if node.length >= 3

    if commandName == 'rule'
      _unpackRuleset2dConstraints node, tailNode, commands, buffer

    else
      _traverseAstFor2DProperties node, headNode, commands, buffer, true

      if tailNode?
        _traverseAstFor2DProperties node, tailNode, commands, buffer

      if !node._has2dProperty && (headNode._has2dProperty or (tailNode? and tailNode._has2dProperty))
        node._has2dProperty = true

      if firstLevelCmd and node._has2dProperty
        _addConstraintForUnpacking commands, node, buffer

_unpackRuleset2dConstraints = (node, tailNode, commands, buffer) =>
  for subCommand, i in tailNode[0..node.length]
    if subCommand instanceof Array
      _analyze subCommand, commands, false, buffer

      if subCommand._has2dProperty
        _addConstraintForUnpacking tailNode, subCommand, buffer

_traverseAstFor2DProperties = (parentNode, node, commands, buffer, isHeadConstraint) =>
  if node instanceof Array and node.length > 0
    nodeLastItem = node[node.length - 1]
    if nodeLastItem not instanceof Array and propertyMapping[nodeLastItem]?
      node._has2dProperty = true
      node._2DPropertyName = nodeLastItem
    else
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
  if node._has2dHeadNode
    _changePropertyName node[1], index1DPropertyName
  if node._has2dTailNode
    _changePropertyName node[2], index1DPropertyName

  _removeTempState node

_changePropertyName = (node, onedPropIndex) =>
  if node instanceof Array
    if node[node.length - 1] == node._2DPropertyName
      node[node.length - 1] = propertyMapping[node._2DPropertyName][onedPropIndex]
    else
      _routeTraversalFor2DExpansion node, onedPropIndex

_clone = (obj) ->
  return obj  if obj is null or typeof (obj) isnt "object"
  temp = new obj.constructor()
  for key of obj
    temp[key] = _clone(obj[key])
  temp

_removeTempState = (node) ->
  delete node._has2dHeadNode
  delete node._has2dTailNode
  delete node._2DPropertyName
  delete node._has2dProperty

propertyMapping =
  'bottom-left'   : ['left', 'bottom']
  'bottom-right'  : ['right', 'bottom']
  center          : ['center-x', 'center-y']
  'intrinsic-size': ['intrinsic-width', 'intrinsic-height']
  position        : ['x', 'y']
  size            : ['width', 'height']
  'top-left'      : ['left', 'top']
  'top-right'     : ['right', 'top']
