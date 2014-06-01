module.exports = ->
  # Project configuration
  @initConfig
    pkg: @file.readJSON 'package.json'

    # Generate library from Peg grammar
    peg:
      ccssCompiler:
        src: 'grammar/ccss-compiler.peg'
        dest: 'lib/ccss-compiler.js'

    # Build the browser Component

    # See https://github.com/anthonyshort/grunt-component-build/issues/40
    exec:
      componentbuild:
        command: './node_modules/.bin/component install; ./node_modules/.bin/component build -o browser -n ccss-compiler'

    # JavaScript minification for the browser
    uglify:
      options:
        report: 'min'
      ccssCompiler:
        files:
          './browser/ccss-compiler.min.js': ['./browser/ccss-compiler.js']

    # Automated recompilation and testing when developing
    watch:
      files: ['spec/*.coffee', 'grammar/*.peg']
      tasks: ['test']

    # BDD tests on Node.js
    cafemocha:
      nodejs:
        src: ['spec/*.coffee']
      options:
        reporter: 'spec'

    # CoffeeScript compilation
    coffee:
      spec:
        options:
          bare: true
        expand: true
        cwd: 'spec'
        src: ['**.coffee']
        dest: 'spec'
        ext: '.js'
      grammar:
        options:
          bare: true
        expand: true
        cwd: 'src'
        src: ['**.coffee']
        dest: 'lib'
        ext: '.js'

    # BDD tests on browser
    mocha_phantomjs:
      all: ['spec/runner.html']

  # Grunt plugins used for building
  @loadNpmTasks 'grunt-peg'
  @loadNpmTasks 'grunt-contrib-uglify'
  @loadNpmTasks 'grunt-exec'

  # Grunt plugins used for testing
  @loadNpmTasks 'grunt-cafe-mocha'
  @loadNpmTasks 'grunt-contrib-coffee'
  @loadNpmTasks 'grunt-mocha-phantomjs'
  @loadNpmTasks 'grunt-contrib-watch'

  @registerTask 'build', ['coffee:grammar', 'peg', 'exec:componentbuild', 'uglify']
  @registerTask 'test', ['build', 'coffee:spec', 'cafemocha', 'mocha_phantomjs']
  @registerTask 'default', ['build']
