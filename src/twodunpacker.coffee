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
    expandsObjs = []
    analyze ast, expandsObjs
    expand2dProperties expandsObjs
    #JSON.parse JSON.stringify ast
    ast

analyze = (ast, expandsObjs) ->
  if ast.commands?
    for node in ast.commands
      _analyze node, ast.commands, true, expandsObjs

_analyze = (node, commands, firstLevelCmd, expandObjs) =>

  if node.length >= 3
    #Is it a parent node?
    commandName = node[0]
    headNode = node[1]
    tailNode = node[2]
    clonedNode = null

    if commandName == 'rule'
      _unpackRuleset2dConstraint node, tailNode, commands, expandObjs

    else
      #analyze the left side of the constraint
      if headNode instanceof Array && headNode.length == 3
        _analyze headNode, commands, false, expandObjs
        if headNode._has2dProperty?
          node._has2dHeadNode = headNode._has2dProperty
          node._head2dPropertyName = headNode._twodPropertyName

      #analyze the right side of the constraint
      if tailNode not instanceof Array
        node._has2dProperty = propertyMapping[tailNode]?
        if node._has2dProperty then node._twodPropertyName = tailNode

      else
        _analyze tailNode, commands, false, expandObjs
        if tailNode._has2dProperty?
          node._has2dTailNode = tailNode._has2dProperty
          node._tail2dPropertyName = tailNode._twodPropertyName

      if node._has2dProperty? == false || !node._has2dProperty
        node._has2dProperty = (headNode._has2dProperty? && headNode._has2dProperty == true) || (tailNode._has2dProperty? && tailNode._has2dProperty == true)

      if firstLevelCmd && node._has2dProperty
        _addConstraintForUnpack commands, node, expandObjs

  if node.length == 2 && node[0] == 'stay'
    _unpackStay2dConstraint node, commands, expandObjs, firstLevelCmd

_unpackRuleset2dConstraint = (node, tailNode, commands, expandObjs) ->
  for subCommand, i in tailNode[0..node.length]
    if subCommand instanceof Array # then recurse
      _analyze subCommand, commands, false, expandObjs

      if subCommand._has2dProperty? && subCommand._has2dProperty
        _addConstraintForUnpack tailNode, subCommand, expandObjs

_unpackStay2dConstraint = (node, commands, expandObjs, firstLevelCmd) ->
  _analyze node[1], commands, false, expandObjs
  if node[1]._has2dProperty?
    node._has2dProperty = node[1]._has2dProperty
    node._twodPropertyName = node[1]._twodPropertyName
    node._has2dHeadNode = node[1]._has2dProperty
    node._head2dPropertyName = node[1]._twodPropertyName

  if firstLevelCmd && node._has2dProperty
    _addConstraintForUnpack commands, node, expandObjs

_addConstraintForUnpack = (commands, node, expandObjs) ->
      expandObjs.push
        toExpand:
          parent: commands
          twodnode: node

_clone = (obj) ->
  return obj  if obj is null or typeof (obj) isnt "object"
  temp = new obj.constructor()
  for key of obj
    temp[key] = _clone(obj[key])
  temp


expand2dProperties = (expandObjs) ->
  #expand the properties correctly considering the order of the .
  for expandNode in expandObjs
    insertionIndex = (expandNode.toExpand.parent.indexOf expandNode.toExpand.twodnode) + 1
    clonedConstraint = _clone expandNode.toExpand.twodnode

    expandNode.toExpand.parent.splice insertionIndex, 0, clonedConstraint

    node = expandNode.toExpand.twodnode

    if node._has2dHeadNode? && node._has2dHeadNode
      _changePropertyName node[1], 0
    if node._has2dTailNode? && node._has2dTailNode
      _changePropertyName node[2], 0

    node = clonedConstraint

    if node._has2dHeadNode? && node._has2dHeadNode
      _changePropertyName node[1], 1
    if node._has2dTailNode? && node._has2dTailNode
      _changePropertyName node[2], 1


_changePropertyName = (node, onedPropIndex) ->
  if node instanceof Array && node.length == 3
    if node[2] == node._twodPropertyName
      node[2] = propertyMapping[node._twodPropertyName][onedPropIndex]
    else
      if node._has2dHeadNode? && node._has2dHeadNode
        _changePropertyName node[1], onedPropIndex
      if node._has2dTailNode? && node._has2dTailNode
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
