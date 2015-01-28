var analyze, expand2dProperties, propertyMapping, _addConstraintForUnpack, _analyze, _changePropertyName, _clone, _unpackRuleset2dConstraint, _unpackStay2dConstraint,
  _this = this;

module.exports = function(ast) {
  var expandsObjs;
  expandsObjs = [];
  analyze(ast, expandsObjs);
  expand2dProperties(expandsObjs);
  return ast;
};

analyze = function(ast, expandsObjs) {
  var node, _i, _len, _ref, _results;
  if (ast.commands != null) {
    _ref = ast.commands;
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      node = _ref[_i];
      _results.push(_analyze(node, ast.commands, true, expandsObjs));
    }
    return _results;
  }
};

_analyze = function(node, commands, firstLevelCmd, expandObjs) {
  var clonedNode, commandName, headNode, tailNode;
  if (node.length >= 3) {
    commandName = node[0];
    headNode = node[1];
    tailNode = node[2];
    clonedNode = null;
    if (commandName === 'rule') {
      _unpackRuleset2dConstraint(node, tailNode, commands, expandObjs);
    } else {
      if (headNode instanceof Array && headNode.length === 3) {
        _analyze(headNode, commands, false, expandObjs);
        if (headNode._has2dProperty != null) {
          node._has2dHeadNode = headNode._has2dProperty;
          node._head2dPropertyName = headNode._twodPropertyName;
        }
      }
      if (!(tailNode instanceof Array)) {
        node._has2dProperty = propertyMapping[tailNode] != null;
        if (node._has2dProperty) {
          node._twodPropertyName = tailNode;
        }
      } else {
        _analyze(tailNode, commands, false, expandObjs);
        if (tailNode._has2dProperty != null) {
          node._has2dTailNode = tailNode._has2dProperty;
          node._tail2dPropertyName = tailNode._twodPropertyName;
        }
      }
      if ((node._has2dProperty != null) === false || !node._has2dProperty) {
        node._has2dProperty = ((headNode._has2dProperty != null) && headNode._has2dProperty === true) || ((tailNode._has2dProperty != null) && tailNode._has2dProperty === true);
      }
      if (firstLevelCmd && node._has2dProperty) {
        _addConstraintForUnpack(commands, node, expandObjs);
      }
    }
  }
  if (node.length === 2 && node[0] === 'stay') {
    return _unpackStay2dConstraint(node, commands, expandObjs, firstLevelCmd);
  }
};

_unpackRuleset2dConstraint = function(node, tailNode, commands, expandObjs) {
  var i, subCommand, _i, _len, _ref, _results;
  _ref = tailNode.slice(0, +node.length + 1 || 9e9);
  _results = [];
  for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
    subCommand = _ref[i];
    if (subCommand instanceof Array) {
      _analyze(subCommand, commands, false, expandObjs);
      if ((subCommand._has2dProperty != null) && subCommand._has2dProperty) {
        _results.push(_addConstraintForUnpack(tailNode, subCommand, expandObjs));
      } else {
        _results.push(void 0);
      }
    } else {
      _results.push(void 0);
    }
  }
  return _results;
};

_unpackStay2dConstraint = function(node, commands, expandObjs, firstLevelCmd) {
  _analyze(node[1], commands, false, expandObjs);
  if (node[1]._has2dProperty != null) {
    node._has2dProperty = node[1]._has2dProperty;
    node._twodPropertyName = node[1]._twodPropertyName;
    node._has2dHeadNode = node[1]._has2dProperty;
    node._head2dPropertyName = node[1]._twodPropertyName;
  }
  if (firstLevelCmd && node._has2dProperty) {
    return _addConstraintForUnpack(commands, node, expandObjs);
  }
};

_addConstraintForUnpack = function(commands, node, expandObjs) {
  return expandObjs.push({
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

expand2dProperties = function(expandObjs) {
  var clonedConstraint, expandNode, insertionIndex, node, _i, _len, _results;
  _results = [];
  for (_i = 0, _len = expandObjs.length; _i < _len; _i++) {
    expandNode = expandObjs[_i];
    insertionIndex = (expandNode.toExpand.parent.indexOf(expandNode.toExpand.twodnode)) + 1;
    clonedConstraint = _clone(expandNode.toExpand.twodnode);
    if (expandNode.toExpand.parent.length === 1) {
      expandNode.toExpand.parent.push(clonedConstraint);
    } else {
      expandNode.toExpand.parent.splice(insertionIndex, 0, clonedConstraint);
    }
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
    if (node[2] === node._twodPropertyName) {
      return node[2] = propertyMapping[node._twodPropertyName][onedPropIndex];
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
