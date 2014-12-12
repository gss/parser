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
    analyze ast, buffer
    mutate buffer
    #JSON.parse JSON.stringify ast
    ast

analyze = (ast, buffer) ->
  if ast.commands?
    for node in ast.commands
      _analyze node, buffer

_analyze = (node, buffer, bufferLengthMinus = 1) =>
  isScope = false
  name = node[0]

  if name is 'rule'
    node._isScope = true
    scope = node
    parent = buffer[buffer.length - 1]
    parent._childScopes.push scope
    scope._parentScope = parent
    scope._childScopes = []
    scope._unscopedVars = []
    buffer.push scope

  else if name is 'get' or name is 'virtual'
    currScope = buffer[buffer.length - bufferLengthMinus]
    if currScope
      if node.length is 2
        node._varKey = node.toString()
        currScope._unscopedVars.push node

  for sub, i in node[0..node.length]
    if sub instanceof Array # then recurse
      # ruleset context is not child of rulset
      if name is 'rule' and i is 1
        _analyze sub, buffer, 2
      else
        _analyze sub, buffer, bufferLengthMinus

  if node._isScope
    buffer.pop()


mutate = (buffer) ->
  for node in buffer[0]._childScopes
    _mutate node

_mutate = (node) =>
  for child in node._childScopes
    _mutate child

  if node._unscopedVars?.length > 0
    for unscoped in node._unscopedVars
      level = 0
      hoistLevel = 0
      parent = node._parentScope
      while parent
        level++
        for upper_unscoped in parent._unscopedVars
          if upper_unscoped._varKey is unscoped._varKey
            hoistLevel = level
        parent = parent._parentScope

      # Hoist unscoped get commands by injecting parent scope operators, `^`
      if hoistLevel > 0
        if unscoped[1][0] isnt '^' # not already hoisted
          hoister = ['^']
          hoister.push(hoistLevel) if hoistLevel > 1
          unscoped.splice 1, 0, hoister
