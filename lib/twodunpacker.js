var buffer2dExpansion, expandConstraintsWith2dProperties, propertyMapping, _buffer2dExpansion, _clone, _rename2dTo1dProperty, _traverseAstFor2DProperties, _unpackRuleset2dConstraints,
  _this = this;

module.exports = function(ast) {
  var buffer;
  buffer = [];
  buffer2dExpansion(ast, buffer);
  expandConstraintsWith2dProperties(buffer);
  return ast;
};

buffer2dExpansion = function(ast, buffer) {
  var node, _i, _len, _ref, _results;
  if (ast.commands != null) {
    _ref = ast.commands;
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      node = _ref[_i];
      _results.push(_buffer2dExpansion(node, ast.commands, buffer));
    }
    return _results;
  }
};

_buffer2dExpansion = function(node, commands, buffer) {
  var childNode, i, _i, _len, _ref;
  if (node.length > 1) {
    if (node[0] === 'rule') {
      _unpackRuleset2dConstraints(node, node[2], buffer);
    } else {
      _ref = node.slice(1, +node.length + 1 || 9e9);
      for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
        childNode = _ref[i];
        if (_traverseAstFor2DProperties(childNode)) {
          if (commands) {
            buffer.push({
              toExpand: {
                commands: commands,
                constraint: node
              }
            });
          }
          return true;
        }
      }
    }
  }
  return false;
};

_unpackRuleset2dConstraints = function(node, commands, buffer) {
  var constraint, i, _i, _len, _ref, _results;
  _ref = commands.slice(0, +commands.length + 1 || 9e9);
  _results = [];
  for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
    constraint = _ref[i];
    _results.push(_buffer2dExpansion(constraint, commands, buffer));
  }
  return _results;
};

_traverseAstFor2DProperties = function(node) {
  if (node instanceof Array && node.length > 0) {
    if (!(node[node.length - 1] instanceof Array) && (propertyMapping[node[node.length - 1]] != null)) {
      return true;
    } else {
      return _buffer2dExpansion(node);
    }
  }
  return false;
};

expandConstraintsWith2dProperties = function(buffer) {
  var clonedConstraint, expansionItem, insertionIndex, _i, _len, _results;
  _results = [];
  for (_i = 0, _len = buffer.length; _i < _len; _i++) {
    expansionItem = buffer[_i];
    clonedConstraint = _clone(expansionItem.toExpand.constraint);
    insertionIndex = 1 + (expansionItem.toExpand.commands.indexOf(expansionItem.toExpand.constraint));
    expansionItem.toExpand.commands.splice(insertionIndex, 0, clonedConstraint);
    _rename2dTo1dProperty(expansionItem.toExpand.constraint, 0);
    _results.push(_rename2dTo1dProperty(clonedConstraint, 1));
  }
  return _results;
};

_rename2dTo1dProperty = function(node, index1DPropertyName) {
  var i, subNode, _i, _len, _ref, _results;
  _ref = node.slice(1, +node.length + 1 || 9e9);
  _results = [];
  for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
    subNode = _ref[i];
    if (subNode instanceof Array) {
      if (propertyMapping[subNode[subNode.length - 1]]) {
        _results.push(subNode[subNode.length - 1] = propertyMapping[subNode[subNode.length - 1]][index1DPropertyName]);
      } else {
        _results.push(_rename2dTo1dProperty(subNode, index1DPropertyName));
      }
    } else {
      _results.push(void 0);
    }
  }
  return _results;
};

_clone = function(obj) {
  return JSON.parse(JSON.stringify(obj));
};

propertyMapping = {
  'bottom-left': ['left', 'bottom'],
  'bottom-right': ['right', 'bottom'],
  center: ['center-x', 'center-y'],
  'intrinsic-size': ['intrinsic-width', 'intrinsic-height'],
  position: ['x', 'y'],
  scale: ['scale-x', 'scale-y'],
  size: ['width', 'height'],
  'top-left': ['left', 'top'],
  'top-right': ['right', 'top']
};
