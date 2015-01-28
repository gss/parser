var analyze, expand2dProperties, propertyMapping, _addConstraintForUnpack, _analyseContraint, _analyze, _changePropertyName, _clone, _traverseTailAstFor2DProperty, _unpackRuleset2dConstraints, _unpackStay2dConstraint,
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
  var clonedNode, commandName, headNode, tailNode;
  if (node.length >= 3) {
    commandName = node[0];
    headNode = node[1];
    tailNode = node[2];
    clonedNode = null;
    if (commandName === 'rule') {
      _unpackRuleset2dConstraints(node, tailNode, commands, buffer);
    } else {
      _analyseContraint(node, headNode, commands, buffer, true);
      _traverseTailAstFor2DProperty(node, tailNode, commands, buffer);
      if (!node._has2dProperty) {
        node._has2dProperty = headNode._has2dProperty || tailNode._has2dProperty;
      }
      if (firstLevelCmd && node._has2dProperty) {
        _addConstraintForUnpack(commands, node, buffer);
      }
    }
  }
  if (node.length === 2 && node[0] === 'stay') {
    return _unpackStay2dConstraint(node, commands, buffer, firstLevelCmd);
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
      if ((subCommand._has2dProperty != null) && subCommand._has2dProperty) {
        _results.push(_addConstraintForUnpack(tailNode, subCommand, buffer));
      } else {
        _results.push(void 0);
      }
    } else {
      _results.push(void 0);
    }
  }
  return _results;
};

_unpackStay2dConstraint = function(node, commands, buffer, firstLevelCmd) {
  _analyze(node[1], commands, false, buffer);
  if (node[1]._has2dProperty != null) {
    node._has2dProperty = node[1]._has2dProperty;
    node._2DPropertyName = node[1]._2DPropertyName;
    node._has2dHeadNode = node[1]._has2dProperty;
    node._head2dPropertyName = node[1]._2DPropertyName;
  }
  if (firstLevelCmd && node._has2dProperty) {
    return _addConstraintForUnpack(commands, node, buffer);
  }
};

_traverseTailAstFor2DProperty = function(parentNode, node, commands, buffer) {
  if (!(node instanceof Array)) {
    parentNode._has2dProperty = propertyMapping[node] != null;
    if (propertyMapping[node] != null) {
      return parentNode._2DPropertyName = node;
    }
  } else {
    return _analyseContraint(parentNode, node, commands, buffer);
  }
};

_analyseContraint = function(parentNode, node, commands, buffer, isHeadConstraint) {
  if (node instanceof Array) {
    _analyze(node, commands, false, buffer);
    if (node._has2dProperty != null) {
      if (isHeadConstraint) {
        parentNode._has2dHeadNode = node._has2dProperty;
        return parentNode._head2dPropertyName = node._2DPropertyName;
      } else {
        parentNode._has2dTailNode = node._has2dProperty;
        return parentNode._tail2dPropertyName = node._2DPropertyName;
      }
    }
  }
};

_addConstraintForUnpack = function(commands, node, buffer) {
  return buffer.push({
    toExpand: {
      parent: commands,
      twodnode: node
    }
  });
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

expand2dProperties = function(buffer) {
  var clonedConstraint, expandNode, insertionIndex, node, _i, _len, _results;
  _results = [];
  for (_i = 0, _len = buffer.length; _i < _len; _i++) {
    expandNode = buffer[_i];
    insertionIndex = (expandNode.toExpand.parent.indexOf(expandNode.toExpand.twodnode)) + 1;
    clonedConstraint = _clone(expandNode.toExpand.twodnode);
    expandNode.toExpand.parent.splice(insertionIndex, 0, clonedConstraint);
    node = expandNode.toExpand.twodnode;
    if ((node._has2dHeadNode != null) && node._has2dHeadNode) {
      _changePropertyName(node[1], 0);
    }
    if ((node._has2dTailNode != null) && node._has2dTailNode) {
      _changePropertyName(node[2], 0);
    }
    node = clonedConstraint;
    if ((node._has2dHeadNode != null) && node._has2dHeadNode) {
      _changePropertyName(node[1], 1);
    }
    if ((node._has2dTailNode != null) && node._has2dTailNode) {
      _results.push(_changePropertyName(node[2], 1));
    } else {
      _results.push(void 0);
    }
  }
  return _results;
};

_changePropertyName = function(node, onedPropIndex) {
  if (node instanceof Array && node.length === 3) {
    if (node[2] === node._2DPropertyName) {
      return node[2] = propertyMapping[node._2DPropertyName][onedPropIndex];
    } else {
      if ((node._has2dHeadNode != null) && node._has2dHeadNode) {
        _changePropertyName(node[1], onedPropIndex);
      }
      if ((node._has2dTailNode != null) && node._has2dTailNode) {
        return _changePropertyName(node[2], onedPropIndex);
      }
    }
  }
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
