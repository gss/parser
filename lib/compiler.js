var ErrorReporter, parser;

if (typeof window !== "undefined" && window !== null) {
  parser = require('./parser');
} else {
  parser = require('../lib/parser');
}

ErrorReporter = require('error-reporter');

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
  }
};
