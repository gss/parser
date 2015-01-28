var analyze, contraintOperator, expand2dProperties, propertyMapping, _analyze, _changePropertyName, _clone,
  _this = this;

module.exports = function(ast) {
  var expandsObjs;
  expandsObjs = [];
  analyze(ast, expandsObjs);
  expand2dProperties(expandsObjs);
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
  var clonedNode, commandName, headNode, i, sub, tailNode, _i, _len, _ref, _results;
  if (node.length === 3) {
    commandName = node[0];
    headNode = node[1];
    tailNode = node[2];
    clonedNode = null;
    if (commandName === 'rule') {
      _ref = tailNode.slice(0, +node.length + 1 || 9e9);
      _results = [];
      for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
        sub = _ref[i];
        if (sub instanceof Array) {
          _analyze(sub, commands, false, expandObjs);
          if (sub.has2dProperty != null) {
            _results.push(expandObjs.push({
              toExpand: {
                parent: tailNode,
                twodnode: sub
              }
            }));
          } else {
            _results.push(void 0);
          }
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    } else {
      if (headNode instanceof Array && headNode.length === 3) {
        _analyze(headNode, commands, false, expandObjs);
        if (headNode.has2dProperty != null) {
          node.has2dHeadNode = headNode.has2dProperty;
          node.head2dPropertyName = headNode.twodPropertyName;
        }
      }
      if (!(tailNode instanceof Array)) {
        node.has2dProperty = propertyMapping[tailNode] != null;
        if (node.has2dProperty) {
          node.twodPropertyName = tailNode;
        }
      } else {
        _analyze(tailNode, commands, false, expandObjs);
        if (tailNode.has2dProperty != null) {
          node.has2dTailNode = tailNode.has2dProperty;
          node.tail2dPropertyName = tailNode.twodPropertyName;
        }
      }
      if ((node.has2dProperty != null) === false || !node.has2dProperty) {
        node.has2dProperty = (headNode.has2dProperty != null) === true || (tailNode.has2dProperty != null) === true;
      }
      if (firstLevelCmd && node.has2dProperty) {
        return expandObjs.push({
          toExpand: {
            parent: commands,
            twodnode: node
          }
        });
      }
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
    if ((node.has2dHeadNode != null) && node.has2dHeadNode) {
      _changePropertyName(node[1], 0);
    }
    if ((node.has2dTailNode != null) && node.has2dTailNode) {
      _changePropertyName(node[2], 0);
    }
    node = clonedConstraint;
    if ((node.has2dHeadNode != null) && node.has2dHeadNode) {
      _changePropertyName(node[1], 1);
    }
    if ((node.has2dTailNode != null) && node.has2dTailNode) {
      _results.push(_changePropertyName(node[2], 1));
    } else {
      _results.push(void 0);
    }
  }
  return _results;
};

_changePropertyName = function(node, onedPropIndex) {
  if (node instanceof Array && node.length === 3) {
    if (node[2] === node.twodPropertyName) {
      return node[2] = propertyMapping[node.twodPropertyName][onedPropIndex];
    } else {
      if ((node.has2dHeadNode != null) && node.has2dHeadNode) {
        _changePropertyName(node[1], onedPropIndex);
      }
      if ((node.has2dTailNode != null) && node.has2dTailNode) {
        return _changePropertyName(node[2], onedPropIndex);
      }
    }
  }
};
