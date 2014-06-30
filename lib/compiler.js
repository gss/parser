var ErrorReporter, parse, parser, vfl, vflHook, vgl, vglHook;

if (typeof window !== "undefined" && window !== null) {
  parser = require('./parser');
} else {
  parser = require('../lib/parser');
}

vfl = require('vfl-compiler');

vgl = require('vgl-compiler');

ErrorReporter = require('error-reporter');

parse = function(source) {
  var columnNumber, error, errorReporter, lineNumber, message, results;
  results = null;
  try {
    results = parser.parse(source);
  } catch (_error) {
    error = _error;
    errorReporter = new ErrorReporter(source);
    message = error.message, lineNumber = error.line, columnNumber = error.column;
    errorReporter.reportError(message, lineNumber, columnNumber);
  }
  return results;
};

vflHook = function(name, terms, commands) {
  var newCommands, s, statements, _i, _len;
  if (commands == null) {
    commands = [];
  }
  newCommands = [];
  statements = vfl.parse("@" + name + " " + terms);
  for (_i = 0, _len = statements.length; _i < _len; _i++) {
    s = statements[_i];
    newCommands = newCommands.concat(parse(s).commands);
  }
  return {
    commands: commands.concat(newCommands)
  };
};

vglHook = function(name, terms, commands) {
  var newCommands, s, statements, _i, _len;
  if (commands == null) {
    commands = [];
  }
  newCommands = [];
  statements = vgl.parse("@" + name + " " + terms);
  for (_i = 0, _len = statements.length; _i < _len; _i++) {
    s = statements[_i];
    newCommands = newCommands.concat(parse(s).commands);
  }
  return {
    commands: commands.concat(newCommands)
  };
};

parser.hooks = {
  directives: {
    'h': vflHook,
    'v': vflHook,
    'horizontal': vflHook,
    'vertical': vflHook,
    'grid-template': vglHook,
    'grid-rows': vglHook,
    'grid-cols': vglHook
  }
};

module.exports = {
  parse: parse
};
