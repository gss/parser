var analyze, expand2dProperties, propertyMapping, _addConstraintForUnpacking, _analyze, _changePropertyName, _clone, _removeTempState, _routeTraversalFor2DExpansion, _traverseAstFor2DProperties, _unpackRuleset2dConstraints,
  _this = this;

module.exports = function(ast) {
  var buffer;
  buffer = [];
  analyze(ast, buffer);
  expand2dProperties(buffer);
  return ast;
};

analyze = function(ast, buffer) {
  var node, _i, _len, _ref, _results;
  if (ast.commands != null) {
    _ref = ast.commands;
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      node = _ref[_i];
      _results.push(_analyze(node, ast.commands, true, buffer));
    }
    return _results;
  }
};

_analyze = function(node, commands, firstLevelCmd, buffer) {
  var commandName, headNode, tailNode;
  if (node.length >= 2) {
    commandName = node[0];
    headNode = node[1];
    if (node.length >= 3) {
      tailNode = node[2];
    }
    if (commandName === 'rule') {
      return _unpackRuleset2dConstraints(node, tailNode, commands, buffer);
    } else {
      _traverseAstFor2DProperties(node, headNode, commands, buffer, true);
      if (tailNode != null) {
        _traverseAstFor2DProperties(node, tailNode, commands, buffer);
      }
      if (!node._has2dProperty && (headNode._has2dProperty || ((tailNode != null) && tailNode._has2dProperty))) {
        node._has2dProperty = true;
      }
      if (firstLevelCmd && node._has2dProperty) {
        return _addConstraintForUnpacking(commands, node, buffer);
      }
    }
  }
};

_unpackRuleset2dConstraints = function(node, tailNode, commands, buffer) {
  var i, subCommand, _i, _len, _ref, _results;
  _ref = tailNode.slice(0, +node.length + 1 || 9e9);
  _results = [];
  for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
    subCommand = _ref[i];
    if (subCommand instanceof Array) {
      _analyze(subCommand, commands, false, buffer);
      if (subCommand._has2dProperty) {
        _results.push(_addConstraintForUnpacking(tailNode, subCommand, buffer));
      } else {
        _results.push(void 0);
      }
    } else {
      _results.push(void 0);
    }
  }
  return _results;
};

_traverseAstFor2DProperties = function(parentNode, node, commands, buffer, isHeadConstraint) {
  var nodeLastItem;
  if (node instanceof Array && node.length > 0) {
    nodeLastItem = node[node.length - 1];
    if (!(nodeLastItem instanceof Array) && (propertyMapping[nodeLastItem] != null)) {
      node._has2dProperty = true;
      node._2DPropertyName = nodeLastItem;
    } else {
      _analyze(node, commands, false, buffer);
    }
    if (node._has2dProperty != null) {
      if (isHeadConstraint) {
        parentNode._has2dHeadNode = node._has2dProperty;
      }
      if (!isHeadConstraint) {
        return parentNode._has2dTailNode = node._has2dProperty;
      }
    }
  }
};

_addConstraintForUnpacking = function(commands, node, buffer) {
  return buffer.push({
    toExpand: {
      parent: commands,
      nodeWith2DProp: node
    }
  });
};

expand2dProperties = function(buffer) {
  var clonedConstraint, expandNode, insertionIndex, _i, _len, _results;
  _results = [];
  for (_i = 0, _len = buffer.length; _i < _len; _i++) {
    expandNode = buffer[_i];
    clonedConstraint = _clone(expandNode.toExpand.nodeWith2DProp);
    insertionIndex = (expandNode.toExpand.parent.indexOf(expandNode.toExpand.nodeWith2DProp)) + 1;
    expandNode.toExpand.parent.splice(insertionIndex, 0, clonedConstraint);
    _routeTraversalFor2DExpansion(expandNode.toExpand.nodeWith2DProp, 0);
    _results.push(_routeTraversalFor2DExpansion(clonedConstraint, 1));
  }
  return _results;
};

_routeTraversalFor2DExpansion = function(node, index1DPropertyName) {
  if (node._has2dHeadNode) {
    _changePropertyName(node[1], index1DPropertyName);
  }
  if (node._has2dTailNode) {
    _changePropertyName(node[2], index1DPropertyName);
  }
  return _removeTempState(node);
};

_changePropertyName = function(node, onedPropIndex) {
  if (node instanceof Array) {
    if (node[node.length - 1] === node._2DPropertyName) {
      return node[node.length - 1] = propertyMapping[node._2DPropertyName][onedPropIndex];
    } else {
      return _routeTraversalFor2DExpansion(node, onedPropIndex);
    }
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

_removeTempState = function(node) {
  delete node._has2dHeadNode;
  delete node._has2dTailNode;
  delete node._2DPropertyName;
  return delete node._has2dProperty;
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
