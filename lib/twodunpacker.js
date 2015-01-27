var analyze, contraintOperator, propertyMapping, _analyze, _clone,
  _this = this;

module.exports = function(ast) {
  var buffer, mapping;
  buffer = [
    {
      _parentScope: void 0,
      _childScopes: [],
      _unscopedVars: []
    }
  ];
  mapping = {
    'bottom-left': ['left', 'bottom'],
    'bottom-right': ['right', 'bottom'],
    center: ['center-x', 'center-y'],
    'intrinsic-size': ['intrinsic-width', 'intrinsic-height'],
    position: ['x', 'y'],
    size: ['width', 'height'],
    'top-left': ['left', 'top'],
    'top-right': ['right', 'top']
  };
  analyze(ast, mapping);
  return ast;
};

propertyMapping = {
  'bottom-left': ['left', 'bottom'],
  'bottom-right': ['right', 'bottom'],
  center: ['center-x', 'center-y'],
  'intrinsic-size': ['intrinsic-width', 'intrinsic-height'],
  position: ['x', 'y'],
  size: ['width', 'height'],
  'top-left': ['left', 'top'],
  'top-right': ['right', 'top']
};

contraintOperator = ['>=', '<=', '=='];

analyze = function(ast, mapping) {
  var node, _i, _len, _ref, _results;
  if (ast.commands != null) {
    _ref = ast.commands;
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      node = _ref[_i];
      _results.push(_analyze(node, ast.commands, true));
    }
    return _results;
  }
};

_analyze = function(node, commands, firstLevelCmd) {
  var clonedNode, commandName, headNode, properties, tailNode;
  if (node.length === 3) {
    commandName = node[0];
    headNode = node[1];
    tailNode = node[2];
    clonedNode = null;
    if (commandName === 'rule') {
      node.isParentNode = true;
      headNode._parentNode = node;
      tailnode._parentNode = node;
    }
    if (headNode instanceof Array && headNode.length === 3) {
      headNode = _analyze(headNode, commands, false);
    }
    if (tailNode instanceof Array && tailNode.length === 3) {
      tailNode = _analyze(tailNode, commands, false);
    } else if (tailNode instanceof Array !== true) {
      properties = propertyMapping[tailNode];
      if (properties != null) {
        node.is2dProperty = true;
      }
    }
    if ((tailNode.is2dProperty != null) || (headNode.is2dProperty != null)) {
      if (node.isParentNode != null) {

      } else if (firstLevelCmd != null) {
        clonedNode = _clone(node);
        commands.push(clonedNode);
      }
    }
    return node;
  }
};

_clone = function(obj) {
  var key, temp;
  if (obj === null || typeof obj !== "object") {
    return obj;
  }
  temp = new obj.constructor();
  for (key in obj) {
    temp[key] = _clone(obj[key]);
  }
  return temp;
};
