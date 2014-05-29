# A CoffeeScript representation of the PEG grammar.
#
class Grammar

  ### Private ###

  # Create an AST from the head and tail of an expression.
  # @private
  #
  # @return [Array]
  #
  @_createExpressionAST: (head, tail) ->
    result = head

    for item, index in tail
      result = [
        tail[index][1]
        result
        tail[index][3]
      ]

    return result


  # Report an error.
  # @private
  #
  # @param message [String] A description of the error.
  # @param lineNumber [Number] The line number where the error occurred.
  # @param columnNumber [Number] The column number where the error occurred.
  # @return [String] The message originally passed to the method.
  #
  @_reportError: (message, input, lineNumber, columnNumber) ->
    error = []
    error.push "Error on line #{lineNumber}, column #{columnNumber}: #{message}"
    error.push ''

    lines = input.split '\n'

    previousLineNumber = lineNumber - 1
    nextLineNumber = lineNumber + 1

    # Ensure that indices only exist if they are in range.
    previousLineIndex = previousLineNumber - 1 if previousLineNumber - 1 >= 0
    currentLineIndex = lineNumber - 1
    nextLineIndex = nextLineNumber - 1 if nextLineNumber - 1 <= lines.length - 1

    # Determine the length of the last line number in order to pad the gutter
    # values and maintain a consistent width.
    lastLineNumber = if nextLineIndex? then nextLineNumber else lineNumber
    longestLineNumberLength = "#{lastLineNumber}".length

    # Draw an arrow pointing to the column.
    # The joined array provides (columnNumber - 1) hyphens.
    errorLocator = "#{Array(columnNumber).join('-')}^"

    context = []
    context.push [previousLineNumber, lines[previousLineIndex], previousLineIndex?]
    context.push [lineNumber, lines[currentLineIndex], true]
    context.push ['^', errorLocator, true]
    context.push [nextLineNumber, lines[nextLineIndex], nextLineIndex?]

    for item in context
      gutterValue = item[0]
      lineValue = item[1]
      condition = item[2]

      padding = Array(longestLineNumberLength - "#{gutterValue}".length + 1).join ' '
      gutterValue = "#{padding}#{gutterValue}"

      error.push "#{gutterValue} : #{lineValue}" if condition

    console.error error.join '\n'

    return message;


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
      'bottom-left': ['left', 'bottom']
      'bottom-right': ['right', 'bottom']
      center: ['center-x', 'center-y']
      'intrinsic-size': ['intrinsic-width', 'intrinsic-height']
      position: ['x', 'y']
      size: ['width', 'height']
      'top-left': ['left', 'top']
      'top-right': ['right', 'top']

    expressions = [expression]
    property = expression[1]
    properties = mapping[property]

    if properties?
      expressions = []

      for item in properties
        expression = expression.slice()
        expression[1] = item
        expressions.push expression

    return expressions


  # @property [Array<Array>] A list of commands.
  # @private
  #
  # @note Assigned in constructor to prevent the array from being passed by
  # reference and shared between all instances.
  #
  _commands: null


  # @property [Array<String>] A list of selectors.
  # @private
  #
  # @note Assigned in constructor to prevent the array from being passed by
  # reference and shared between all instances.
  #
  _selectors: null


  # Add a command to @_commands.
  # @private
  #
  # @param command [Array]
  #
  _addCommand: (command) ->
    @_commands.push command


  # Add a selector to @_selectors, if not already in the list.
  # @private
  #
  # @param selector [String] A selector.
  # @return [String] The selector originally passed to the method.
  #
  _addSelector: (selector) ->
    return unless selector?
    @_selectors.push selector if selector not in @_selectors
    return selector


  # Get the current column number as reported by the parser.
  # @note Assigned in constructor.
  # @private
  #
  # @return [Number] The current column number.
  #
  _column: ->


  # Get the current input string as reported by the parser.
  # @note Assigned in constructor.
  # @private
  #
  # @return [String] the current input string.
  #
  _input: ->


  # Get the current line number as reported by the parser.
  # @note Assigned in constructor.
  # @private
  #
  # @return [Number] The current line number.
  #
  _line: ->




  ### Public ###

  # Construct a new Grammar.
  #
  # @param input [Function] A getter for the current input string.
  # @param line [Function] A getter for the current line number.
  # @param column [Function] A getter for the current column number.
  #
  constructor: (input, line, column) ->
    @_commands = []
    @_selectors = []
    @_input = input
    @_line = line
    @_column = column


  # The start rule.
  #
  # @return [Object] An object consisting of commands and selectors.
  #
  start: ->
    return {
      commands: JSON.parse(JSON.stringify(@_commands))
      selectors: @_selectors
    }


  # Statements.
  #
  # @return [Object] An object consisting of functions for handling various
  # types of statement.
  #
  statement: ->
    return {
      linearConstraint: (expression) -> expression
      virtual: (virtual) -> virtual
      conditional: (conditional) -> conditional
      stay: (stay) -> stay
      chain: (chain) -> chain
      forEach: (javaScript) -> javaScript
    }


  # And / Or expressions.
  #
  # @param head [Array]
  # @param tail [Array]
  # @return [Array]
  #
  andOrExpression: (head, tail) ->
    return Grammar._createExpressionAST head, tail


  # And / Or operators.
  #
  # @return [Object]
  #
  andOrOperator: ->
    return {
      and: -> '&&'
      or: -> '||'
    }


  # Conditional expressions.
  #
  # @param head [Array]
  # @param tail [Array]
  # @return [Array]
  #
  conditionalExpression: (head, tail) ->
    return Grammar._createExpressionAST head, tail


  # Conditional operators.
  #
  # @return [Object]
  #
  conditionalOperator: ->
    return {
      equal: -> '?=='
      gt: -> '?>'
      gte: -> '?>='
      lt: -> '?<'
      lte: -> '?<='
      notEqual: -> '?!='
    }


  # Linear constraints.
  #
  # @param head [Array]
  # @param tail [Array]
  # @param strengthAndWeight [Array]
  # @return [String]
  #
  linearConstraint: (head, tail, strengthAndWeight) ->
    firstExpression = head

    if not strengthAndWeight? or strengthAndWeight.length is 0
      strengthAndWeight = []

    for item, index in tail
      operator = tail[index][1]
      secondExpression = tail[index][3]
      headExpressions = Grammar._unpack2DExpression firstExpression
      tailExpressions = Grammar._unpack2DExpression secondExpression

      for tailExpression, index in tailExpressions
        headExpression = headExpressions[index]

        # Correctly handle expressions with a mix of 1D and 2D properties.
        #
        # e.g.
        # #box1[size] == #box2[width];
        #
        # becomes
        # #box1[width] == #box2[width];
        #
        if headExpression? and tailExpression?
          if headExpressions.length > tailExpressions.length
            headExpression[1] = tailExpression[1]
          else if headExpressions.length < tailExpressions.length
            tailExpression[1] = headExpression[1]

          command = [
            operator
            headExpression
            tailExpression
          ].concat strengthAndWeight

          @_addCommand command

      firstExpression = secondExpression

    return "LinaearExpression" # FIXME


  # Linear constraint operators.
  #
  # @return [Object]
  #
  linearConstraintOperator: ->
    return {
      equal: -> 'eq'
      gt: -> 'gt'
      gte: -> 'gte'
      lt: -> 'lt'
      lte: -> 'lte'
    }


  # Constraint additive expressions.
  #
  # @param head [Array]
  # @param tail [Array]
  # @return [Array]
  #
  constraintAdditiveExpression: (head, tail) ->
    return Grammar._createExpressionAST head, tail


  # Additive expressions.
  #
  # @param head [Array]
  # @param tail [Array]
  # @return [Array]
  #
  additiveExpression: (head, tail) ->
    return Grammar._createExpressionAST head, tail


  # Additive operators.
  #
  # @return [Object]
  #
  additiveOperator: ->
    return {
      plus: -> 'plus'
      minus: -> 'minus'
    }


  # Constraint multiplicative expressions.
  #
  # @param head [Array]
  # @param tail [Array]
  # @return [Array]
  #
  constraintMultiplicativeExpression: (head, tail) ->
    return Grammar._createExpressionAST head, tail


  # Multiplicative expressions.
  #
  # @param head [Array]
  # @param tail [Array]
  # @return [Array]
  #
  multiplicativeExpression: (head, tail) ->
    return Grammar._createExpressionAST head, tail


  # Multiplicative operators.
  #
  # @return [Object]
  #
  multiplicativeOperator: ->
    return {
      multiply: -> 'multiply'
      divide: -> 'divide'
    }


  # Constraint primary expressions.
  #
  # @param expression [Array]
  # @return [Object]
  #
  constraintPrimaryExpression: ->
    return {
      constraintAdditiveExpression: (expression) -> expression
    }


  # Primary expressions.
  #
  # @param expression [Array]
  # @return [Object]
  #
  primaryExpression: ->
    return {
      andOrExpression: (expression) -> expression
    }


  # Variables.
  #
  # @param selector [Object]
  # @param variableNameCharacters [Array<String>]
  # @return [Array]
  #
  variable: (selector, variableNameCharacters) ->
    variableName = variableNameCharacters.join ''

    # If bound to DOM query
    #
    if selector? and selector.length isnt 0
      {selector:selectorName} = selector
      @_addSelector selectorName

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
      if selectorName is '::window'
        switch variableName
          when 'right'
            variableName = 'width'
            break
          when 'bottom'
            variableName = 'height'
            break

    if selector? and (selectorName? or selector.isVirtual?)
      return ['get$', variableName, selector.ast]
    else
      return ['get', "[#{variableName}]"]


  # Literals.
  #
  # @param value [Number]
  # @return [Array]
  #
  literal: (value) -> ['number', value]


  # Integers.
  #
  # @param digits [Array<Number>]
  # @return [Number]
  #
  integer: (digits) ->
    return parseInt digits.join(''), 10


  # Reals.
  #
  # @param digits [Array<Number>]
  # @return [Number]
  #
  real: (digits) ->
    return parseFloat digits.join('')




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

        return {
          selector: "##{selectorName}"
          ast: ['$id', selectorName]
        }


      # Reserved pseudo selectors.
      #
      # @param selectorName [String]
      # @return [Object]
      #
      reservedPseudoSelector: (selectorName) ->
        return {
          selector: "::#{selectorName}"
          ast: ['$reserved', selectorName]
        }


      # Virtuals.
      #
      # @param nameCharacters [Array<String>]
      # @return [Object]
      #
      virtual: (nameCharacters) ->
        name = Grammar._toString nameCharacters

        return {
          isVirtual: true
          ast: ['$virtual', name]
        }


      # Classes.
      #
      # @param nameCharacters [Array<String>]
      # @return [Object]
      #
      class: (nameCharacters) ->
        selectorName = Grammar._toString nameCharacters

        return {
          selector: ".#{selectorName}"
          ast: ['$class', selectorName]
        }


      # Tags.
      #
      # @param nameCharacters [Array<String>]
      # @return [Object]
      #
      tag: (nameCharacters) ->
        selectorName = Grammar._toString nameCharacters

        return {
          selector: selectorName
          ast: ['$tag', selectorName]
        }


      # Advanced selectors.
      #
      # @param parts [Array<String>]
      # @return [Object]
      #
      all: (parts) ->
        selector = Grammar._toString parts

        return {
          selector: selector
          ast: ['$all', selector]
        }

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


  # Reserved pseudo selectors.
  #
  # @return [Object]
  #
  reservedPseudoSelector: ->
    return {
      window: -> 'window'
      this: -> 'this'
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
      # @return [String] A message explaining the validity of the directive.
      #
      invalid: =>
        return Grammar._reportError 'Invalid Strength or Weight', @_input(), @_line(), @_column()

    }


  # Weight directives.
  #
  # @param weight [Array<Number>]
  # @return [Number]
  #
  weight: (weight) ->
    return Number weight.join('')


  # Strength directives.
  #
  # @return [Object]
  #
  strength: (strength) ->
    return {
      require: -> 'require'
      strong: -> 'strong'
      medium: -> 'medium'
      weak: -> 'weak'
      required: -> 'require'
    }




  ### Virtual Elements ###

  # Virtual elements.
  #
  # @param names[Array<String>]
  # @return [Array]
  #
  virtualElement: (names) ->
    command = ['virtual'].concat names
    @_addCommand command
    return command


  # Virtual element names.
  #
  # @param namesCharacters[Array<String>]
  # @return [String]
  #
  virtualElementName: (nameCharacters) -> nameCharacters.join ''




  ### Stays ###

  # Stays.
  #
  # @param [Array] variables
  # @return [Array]
  #
  stay: (variables) ->
    stay = ['stay'].concat variables
    expressions = Grammar._unpack2DExpression stay[1]

    for expression, index in expressions
      command = stay.slice()
      command[1] = expressions[index]
      @_addCommand command

    return stay


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
    @_addCommand result
    return result




  ### JavaScript hooks ###

  # For each statements.
  #
  # @param type [String]
  # @param selector [Object]
  # @param javaScript [Array<String>]
  #
  forEach: (type, selector, javaScript) ->
    {selector:selectorName} = selector
    @_addSelector selectorName
    @_addCommand [type, selector.ast, javaScript]


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
    {selector:selectorName} = selector
    @_addSelector selectorName

    ast = ['chain', selector.ast]
    ast = ast.concat chainer for chainer in chainers
    @_addCommand ast


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

    createChainAST = (operator, firstExpression, secondExpression) ->
      ast = [operator, firstExpression, secondExpression]
      ast = ast.concat strengthAndWeight if strengthAndWeight?
      return ast

    tail = head if tail.length is 0

    if headExpression?
      headExpression.splice 1, 1, head
      head = headExpression

    headAST = createChainAST headOperator, head, tail
    headAST = createChainAST headOperator, head, bridgeValue if bridgeValue?
    asts.push headAST

    if bridgeValue? and tailOperator?
      tailAST = createChainAST tailOperator, bridgeValue, tail
      asts.push tailAST
    else
      Grammar._reportError 'Invalid Chain Statement', @_input(), @_line(), @_column()

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
  chainLinearConstraintOperator: (operator = 'eq') ->
    operator = "#{operator}-chain"
    return operator


module.exports = Grammar
