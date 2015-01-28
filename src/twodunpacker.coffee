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

analyze = (ast, expandsObjs) ->
  if ast.commands?
    for node in ast.commands
      _analyze node, ast.commands, true, expandsObjs

_analyze = (node, commands, firstLevelCmd, expandObjs) =>

  if node.length == 3
    #Is it a parent node?
    commandName = node[0]
    headNode = node[1]
    tailNode = node[2]
    clonedNode = null

    if commandName == 'rule'
      #for each tailNode (list of constraints of the ruleset),
      #check wether they are a 2d.
      for sub, i in tailNode[0..node.length]
        if sub instanceof Array # then recurse
          _analyze sub, commands, false, expandObjs

          if sub.has2dProperty?
            expandObjs.push
              toExpand:
                parent: tailNode
                twodnode: sub

    else
      #analyze the left side of the constraint
      if headNode instanceof Array && headNode.length == 3
        _analyze headNode, commands, false, expandObjs
        if headNode.has2dProperty?
          node.has2dHeadNode = headNode.has2dProperty
          node.head2dPropertyName = headNode.twodPropertyName

      #analyze the right side of the constraint
      if tailNode not instanceof Array
        node.has2dProperty = propertyMapping[tailNode]?
        if node.has2dProperty then node.twodPropertyName = tailNode

      else
        _analyze tailNode, commands, false, expandObjs
        if tailNode.has2dProperty?
          node.has2dTailNode = tailNode.has2dProperty
          node.tail2dPropertyName = tailNode.twodPropertyName

      if node.has2dProperty? == false || !node.has2dProperty
        node.has2dProperty = headNode.has2dProperty? == true || tailNode.has2dProperty? == true

      if firstLevelCmd && node.has2dProperty
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

    if expandNode.toExpand.parent.length == 1
      expandNode.toExpand.parent.push clonedConstraint
    else
      expandNode.toExpand.parent.splice insertionIndex, 0, clonedConstraint

    node = expandNode.toExpand.twodnode

    if node.has2dHeadNode? && node.has2dHeadNode
      _changePropertyName node[1], 0
    if node.has2dTailNode? && node.has2dTailNode
      _changePropertyName node[2], 0

    node = clonedConstraint

    if node.has2dHeadNode? && node.has2dHeadNode
      _changePropertyName node[1], 1
    if node.has2dTailNode? && node.has2dTailNode
      _changePropertyName node[2], 1


_changePropertyName = (node, onedPropIndex) ->

  if node instanceof Array && node.length == 3
    if node[2] == node.twodPropertyName
      node[2] = propertyMapping[node.twodPropertyName][onedPropIndex]
    else
      if node.has2dHeadNode? && node.has2dHeadNode
        _changePropertyName node[1], onedPropIndex
      if node.has2dTailNode? && node.has2dTailNode
        _changePropertyName node[2], onedPropIndex
