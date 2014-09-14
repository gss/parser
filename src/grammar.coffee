# A CoffeeScript representation of the PEG grammar.
#
class Grammar

  ### Private ###


  # Create a string from a list of characters.
  # @private
  #
  # @param input [Array<String>, String] A list of characters, or a string.
  # @return [String] A string representation of the object passed to the
  # method.
  #
  @_toString: (input) ->
    return input if toString.call(input) is '[object String]'
    return input.join('') if toString.call(input) is '[object Array]'
    return ''


  # Unpack a 2D expression.
  # @private
  #
  # @param expression [Array] An AST representing a 2D expression.
  # @return [Array] An AST representing the unpacked expression.
  #
  @_unpack2DExpression: (expression) ->
    mapping =
      'bottom-left'   : ['left', 'bottom']
      'bottom-right'  : ['right', 'bottom']
      center          : ['center-x', 'center-y']
      'intrinsic-size': ['intrinsic-width', 'intrinsic-height']
      position        : ['x', 'y']
      size            : ['width', 'height']
      'top-left'      : ['left', 'top']
      'top-right'     : ['right', 'top']

    expressions = [expression]
    property = expression[2]
    properties = mapping[property]

    if properties?
      expressions = []

      for item in properties
        expression = expression.slice()
        expression[2] = item
        expressions.push expression

    return expressions


  # The type of error thrown by the PEG parser.
  # @note Assigned in constructor.
  # @private
  #
  # @param message [String] A description of the error.
  # @param expected [Array<Object>] A list of objects consisting of type,
  # value and description keys which represent valid statements.
  # @param found [String] The statement that found and caused the error.
  # @param offset [Number] The same as `column`, but zero-based.
  # @param line [Number] The line number where the error occurred.
  # @param column [Number] The column number where the error occurred.
  #
  _Error: null



  # Get the current column number as reported by the parser.
  # @note Assigned in constructor.
  # @private
  #
  # @return [Number] The current column number.
  #
  _columnNumber: ->


  # Get the current line number as reported by the parser.
  # @note Assigned in constructor.
  # @private
  #
  # @return [Number] The current line number.
  #
  _lineNumber: ->




  ### Public ###
  
  reverseFilterNest: (commands) ->
    len = commands.length;
    i=len-1
    while i > 0
      commands[i].splice 1, 0, commands[i-1]
      i--
    return commands[len-1]
    
  
  # Create an AST from the head and tail of an expression.
  # @private
  #
  # @return [Array]
  #
  nestedDualTermCommands: (head, tail) ->
    result = head

    for item, index in tail
      result = [
        tail[index][1]
        result
        tail[index][3]
      ]

    return result
    
  createSelectorCommaCommand: (head, tail) ->
    result = [',',head]

    for item, index in tail
      result.push tail[index][3]

    return result
  
  mergeCommands: (objs) ->
    commands = []
    for o in objs
      commands = commands.concat o.commands
    return {commands:commands}

  # Construct a new Grammar.
  #
  # @param lineNumber [Function] A getter for the current line number.
  # @param columnNumber [Function] A getter for the current column number.
  # @param errorType [Function] A getter for the type of error thrown by the
  # PEG parser.
  #
  constructor: (parser, lineNumber, columnNumber, errorType) ->
    @parser = parser
    
    @_lineNumber = lineNumber
    @_columnNumber = columnNumber
    @_Error = errorType()

    
  # constraints.
  #
  # @param head [Array]
  # @param tail [Array]
  # @param strengthAndWeight [Array]
  # @return [String]
  #
  constraint: (head, tail, strengthAndWeight) ->
    
    commands = []
    
    firstExpression = head

    if not strengthAndWeight? or strengthAndWeight.length is 0
      strengthAndWeight = []

    for item, index in tail
      operator = tail[index][1]
      secondExpression = tail[index][3]
      headExpressions = Grammar._unpack2DExpression firstExpression
      tailExpressions = Grammar._unpack2DExpression secondExpression

      # Correctly handle expressions with a mix of 1D and 2D properties.
      #
      # e.g.
      # #box1[size] == #box2[width];
      #
      # becomes
      # #box1[width] == #box2[width];
      # #box1[height] == #box2[width];
      #
      if headExpressions.length > tailExpressions.length
        tailExpressions.push tailExpressions[0]
      else if headExpressions.length < tailExpressions.length
        headExpressions.push headExpressions[0]

      for tailExpression, index in tailExpressions
        headExpression = headExpressions[index]

        if headExpression? and tailExpression?
          command = [
            operator
            headExpression
            tailExpression
          ].concat strengthAndWeight

          commands.push command

      firstExpression = secondExpression

    return {commands:commands} # FIXME
  
  
  # constraints.
  #
  # x: == 100;
  #
  inlineConstraint: (prop,op,rest) ->
    prop = prop.join('').trim()
    rest = rest.join('').trim()     
    
    result = @parser.parse("&[#{prop}] #{op} #{rest}")
    
    
    return result
  
  
  # constraints.
  #
  # x: == 100;
  #
  inlineSet: (prop,rest) ->
    prop = prop.join('').trim()
    rest = rest.join('').trim()
    
    commands = [['set',prop,rest]]
    
    return {commands:commands}
  
  
  # Directives
  #
  directive: (name,terms,commands) ->
    hook = @parser.hooks.directives[name]
    if hook then return hook(name,terms,commands)
    ast = ['directive',name,terms]
    if commands
      ast.push commands
    return {commands:[ast]}

  # Variables.
  #
  # @param selector [Object]
  # @param variableNameCharacters [Array<String>]
  # @return [Array]
  #
  variable: (negative, selector, variableNameCharacters) ->
    variableName = variableNameCharacters.join ''
    
    # If bound to DOM query
    #
    if selector? and selector.length isnt 0

      # Normalize variables names when query bound
      #
      switch variableName
        when 'left'
          variableName = 'x'
          break
        when 'top'
          variableName = 'y'
          break
        when 'cx'
          variableName = 'center-x'
          break
        when 'cy'
          variableName = 'center-y'
          break

      # Normalize window variable names
      #
      if selector.toString().indexOf('$reserved,window') isnt -1
        switch variableName
          when 'right'
            variableName = 'width'
            break
          when 'bottom'
            variableName = 'height'
            break

    if selector?
      command = ['get', selector, variableName]
    else
      command = ['get', variableName]
    
    if negative
      return ['-', 0, command]
    else
      return command




  # Integers.
  #
  # @param digits [Array<Number>]
  # @return [Number]
  #
  integer: (digits) ->
    return parseInt digits.join(''), 10


  # Signed integers.
  #
  # @param sign [String]
  # @param integer [Number]
  # @return [Number]
  #
  signedInteger: (sign, integer = 0) ->
    return parseInt "#{sign}#{integer}", 10


  # Signed reals.
  #
  # @param sign [String]
  # @param real [Number]
  # @return [Number]
  #
  signedReal: (sign, real = 0) ->
    return parseFloat "#{sign}#{real}"




  ### Query selectors ###

  # Selectors.
  #
  # @return [Object]
  #
  selector: ->
    return {

      # ID selectors.
      #
      # @param nameCharacters [Array<String>]
      # @return [Object]
      #
      id: (nameCharacters) ->
        selectorName = Grammar._toString nameCharacters

        return ['$id', selectorName]


      # Reserved pseudo selectors.
      #
      # @param selectorName [String]
      # @return [Object]
      #
      reservedPseudoSelector: (selectorName) ->
        return ['$reserved', selectorName]


      # Virtuals.
      #
      # @param nameCharacters [Array<String>]
      # @return [Object]
      #
      virtual: (nameCharacters) ->
        name = Grammar._toString nameCharacters

        return ['$virtual', name]


      # Classes.
      #
      # @param nameCharacters [Array<String>]
      # @return [Object]
      #
      class: (nameCharacters) ->
        selectorName = Grammar._toString nameCharacters

        return ['$class', selectorName]


      # Tags.
      #
      # @param nameCharacters [Array<String>]
      # @return [Object]
      #
      tag: (nameCharacters) ->
        selectorName = Grammar._toString nameCharacters

        return ['$tag', selectorName]


      # Advanced selectors.
      #
      # @param parts [Array<String>]
      # @return [Object]
      #
      all: (parts) ->
        selector = Grammar._toString parts

        return ['$all', selector]

    }


  # Query selector parts.
  #
  # @return [Object]
  #
  querySelectorAllParts: ->
    return {

      withoutParens: (selectorCharacters) ->
        return Grammar._toString selectorCharacters

      withParens: (selectorCharacters) ->
        selector = Grammar._toString selectorCharacters
        return "(#{selector})"

    }


  ### Strength and weight directives ###

  # Strength and weight directives.
  #
  # @return [Object]
  #
  strengthAndWeight: ->
    return {

      # Valid strength and weight directives.
      #
      # @param strength [String]
      # @param weight [String]
      # @return [Array<String>]
      #
      valid: (strength, weight) ->
        return [strength] if not weight? or weight.length is 0
        return [strength, weight]


      # Invalid strength and weight directives.
      #
      invalid: =>
        throw new @_Error 'Invalid Strength or Weight', null, null, null, @_lineNumber(), @_columnNumber()

    }



  ### Virtual Elements ###

  # Virtual elements.
  #
  # @param names[Array<String>]
  # @return [Array]
  #
  virtualElement: (names) ->
    return {commands:[['virtual'].concat(names)]}




  ### Stays ###

  # Stays.
  #
  # @param [Array] variables
  # @return [Array]
  #
  stay: (variables) ->
    stay = ['stay'].concat variables
    expressions = Grammar._unpack2DExpression stay[1]
    commands = []
    for expression, index in expressions
      command = stay.slice()
      command[1] = expressions[index]
      commands.push command
    return {commands:commands}


  # Stay variables.
  #
  # @param [Array] variable
  # @return [Array]
  #
  stayVariable: (variable) -> variable




  ### Conditionals ###

  # Conditionals.
  #
  # @param result [Array]
  # @return [Array]
  conditional: (result) ->
    commands = [result]
    return {commands:commands}




  ### JavaScript hooks ###

  # For each statements.
  #
  # @param type [String]
  # @param selector [Object]
  # @param javaScript [Array<String>]
  #
  forEach: (type, selector, javaScript) ->
    return {commands:[[type, selector, javaScript]]}


  # JavaScript statements.
  #
  # @param characters [Array<String>]
  # @return [Array<String>]
  #
  javaScript: (characters) ->
    return [
      'js'
      characters.join('').trim()
    ]


  # For loop types.
  #
  # @return [Object];
  #
  forLoopType: ->
    return {
      forEach: -> 'for-each'
      forAll: -> 'for-all'
    }




  ### Chains ###

  # Chains.
  #
  # @param selector [Object]
  # @param chainers [Array]
  #
  chain: (selector, chainers) ->

    ast = ['chain', selector]
    ast = ast.concat chainer for chainer in chainers
    return {commands:[ast]}


  # Chainers.
  #
  # @param [Object] options
  # @option options headCharacters [Array<String>]
  # @option options headExpression [Array]
  # @option options headOperator [String]
  # @option options bridgeValue [Array]
  # @option options tailOperator [String]
  # @option options strengthAndWeight [Array]
  # @option options tailCharacters [Array<String>]
  # @return [Array]
  #
  chainer: (options) =>
    {
      headCharacters
      headExpression
      headOperator
      bridgeValue
      tailOperator
      strengthAndWeight
      tailCharacters
    } = options

    asts = []
    head = Grammar._toString headCharacters
    tail = Grammar._toString tailCharacters

    createChainAST = (operator, firstExpression, secondExpression) =>
      ast = [operator, firstExpression, secondExpression]
      ast = ast.concat strengthAndWeight if strengthAndWeight?
      return ast

    tail = head if tail.length is 0

    if headExpression?
      headExpression.splice 1, 1, head
      head = headExpression

    if bridgeValue?
      asts.push createChainAST(headOperator, head, bridgeValue)

      if tailOperator?
        asts.push createChainAST(tailOperator, bridgeValue, tail)
      else
        throw new @_Error 'Invalid Chain Statement', null, null, null, @_lineNumber(), @_columnNumber()
    else
      asts.push createChainAST(headOperator, head, tail)

    return asts


  # Head expressions.
  #
  # @param operator [String]
  # @param expression [Array]
  # @return [Array]
  #
  headExpression: (operator, expression) ->
    return [operator, '_REPLACE_ME_', expression]


  # Tail expressions.
  #
  # @param expression [Array]
  # @param operator [String]
  # @return [Array]
  #
  tailExpression: (expression, operator) ->
    return [operator, expression, '_REPLACE_ME_']


  # Chain math operators.
  #
  # @return [Object]
  chainMathOperator: ->
    return {
      plus: -> 'plus-chain'
      minus: -> 'minus-chain'
      multiply: -> 'multiply-chain'
      divide: -> 'divide-chain'
    }


  # Chain linear constraint operators.
  #
  # @param operator [String]
  # @return [String]
  #
  chainConstraintOperator: (op = '==') ->
    opMap = 
      "==": "eq"   
      "<=": "lte"  
      ">=": "gte"  
      "<" : "lt"   
      ">" : "gt"   
    operator = "#{opMap[op]}-chain"
    return operator


module.exports = Grammar
