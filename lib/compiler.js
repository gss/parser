var ErrorReporter, parser, subparser;

if (typeof window !== "undefined" && window !== null) {
  parser = require('./parser');
  subparser = require('./parser');
} else {
  parser = require('../lib/parser');
  subparser = require('../lib/parser');
}

ErrorReporter = require('error-reporter');

parser.boob = true;

module.exports = {
  parse: function(source) {
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
  },
  subparse: function(source) {
    var columnNumber, error, errorReporter, lineNumber, message, results;
    results = null;
    try {
      results = subparser.parse(source);
    } catch (_error) {
      error = _error;
      errorReporter = new ErrorReporter(source);
      message = error.message, lineNumber = error.line, columnNumber = error.column;
      errorReporter.reportError(message, lineNumber, columnNumber);
    }
    return results;
  }
};
