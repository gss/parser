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
    clonedNode = null

    if commandName == 'rule'
      _unpackRuleset2dConstraints node, tailNode, commands, buffer
    else
      _analyseContraint node, headNode, commands, buffer, true
      _traverseTailAstFor2DProperty node, tailNode, commands, buffer

      if !node._has2dProperty
        node._has2dProperty = headNode._has2dProperty or tailNode._has2dProperty

      if firstLevelCmd and node._has2dProperty
        _addConstraintForUnpack commands, node, buffer

  if node.length == 2 and node[0] == 'stay'
    _unpackStay2dConstraint node, commands, buffer, firstLevelCmd

_unpackRuleset2dConstraints = (node, tailNode, commands, buffer) =>
  for subCommand, i in tailNode[0..node.length]
    if subCommand instanceof Array # then recurse
      _analyze subCommand, commands, false, buffer

      if subCommand._has2dProperty? and subCommand._has2dProperty
        _addConstraintForUnpack tailNode, subCommand, buffer

_unpackStay2dConstraint = (node, commands, buffer, firstLevelCmd) =>
  _analyze node[1], commands, false, buffer
  if node[1]._has2dProperty?
    node._has2dProperty = node[1]._has2dProperty
    node._2DPropertyName = node[1]._2DPropertyName
    node._has2dHeadNode = node[1]._has2dProperty
    node._head2dPropertyName = node[1]._2DPropertyName

  if firstLevelCmd and node._has2dProperty
    _addConstraintForUnpack commands, node, buffer


# Ultimately the 2D property will always be in the tail of an AST node.
_traverseTailAstFor2DProperty = (parentNode, node, commands, buffer) =>
  if node not instanceof Array
    parentNode._has2dProperty = propertyMapping[node]?
    if propertyMapping[node]?
      parentNode._2DPropertyName = node
  else
    _analyseContraint parentNode, node, commands, buffer

_analyseContraint = (parentNode, node, commands, buffer, isHeadConstraint) =>
  if node instanceof Array
    _analyze node, commands, false, buffer
    if node._has2dProperty?
      if isHeadConstraint
        parentNode._has2dHeadNode = node._has2dProperty
        parentNode._head2dPropertyName = node._2DPropertyName
      else
        parentNode._has2dTailNode = node._has2dProperty
        parentNode._tail2dPropertyName = node._2DPropertyName

_addConstraintForUnpack = (commands, node, buffer) =>
      buffer.push
        toExpand:
          parent: commands
          twodnode: node

_clone = (obj) ->
  return obj  if obj is null or typeof (obj) isnt "object"
  temp = new obj.constructor()
  for key of obj
    temp[key] = _clone(obj[key])
  temp


expand2dProperties = (buffer) ->
  #expand the properties correctly considering the order of the .
  for expandNode in buffer
    insertionIndex = (expandNode.toExpand.parent.indexOf expandNode.toExpand.twodnode) + 1
    clonedConstraint = _clone expandNode.toExpand.twodnode

    expandNode.toExpand.parent.splice insertionIndex, 0, clonedConstraint

    node = expandNode.toExpand.twodnode

    if node._has2dHeadNode? and node._has2dHeadNode
      _changePropertyName node[1], 0
    if node._has2dTailNode? and node._has2dTailNode
      _changePropertyName node[2], 0

    node = clonedConstraint

    if node._has2dHeadNode? and node._has2dHeadNode
      _changePropertyName node[1], 1
    if node._has2dTailNode? and node._has2dTailNode
      _changePropertyName node[2], 1


_changePropertyName = (node, onedPropIndex) =>
  if node instanceof Array and node.length == 3
    if node[2] == node._2DPropertyName
      node[2] = propertyMapping[node._2DPropertyName][onedPropIndex]
    else
      if node._has2dHeadNode? and node._has2dHeadNode
        _changePropertyName node[1], onedPropIndex
      if node._has2dTailNode? and node._has2dTailNode
        _changePropertyName node[2], onedPropIndex

propertyMapping =
  'bottom-left'   : ['left', 'bottom']
  'bottom-right'  : ['right', 'bottom']
  center          : ['center-x', 'center-y']
  'intrinsic-size': ['intrinsic-width', 'intrinsic-height']
  position        : ['x', 'y']
  size            : ['width', 'height']
  'top-left'      : ['left', 'top']
  'top-right'     : ['right', 'top']
