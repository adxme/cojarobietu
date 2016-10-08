module.exports = (grunt) ->
  json = grunt.file.readJSON 'package.json'
  path = require 'path'
  rimraf = require 'rimraf'
  minimatch = require 'minimatch'
  util = require 'util'

  grunt.initConfig
    pkg: json
    coffee: compile:
      options: bare: true
      files: [
        expand: true
        cwd: 'src/scripts'
        src: [ '**/*.coffee' ]
        dest: 'dist/assets/scripts'
        ext: '.js'
      ]

    pug: compile:
      options:
        data: ->
          # index.html dir
          main = 'homepage'
          # scripts loaded after body dir
          after = 'afterload'
          res = obj = {}
          file = this.dest.replace(/(^dist\/|\.html$)/gi, '').split('/')[0]
          file = main if file == 'index'

          template =
            css: '<link rel=\'stylesheet\' href=\'%s\'>',
            js:  '<script src=\'%s\'></script>'

          files =
            css: (src) ->
              grunt.file.expand cwd: 'dist', [
                'assets/styles/reset.css'
                'assets/styles/importer.css'
                'assets/styles/**/*.css'
              ]
            js: (src) ->
              grunt.file.expand cwd: 'dist', [
                'assets/scripts/**/*.js'
                # folder support
                unless !src or src.endsWith '.js' then src+'/**/*.js' else '!'+(+new Date)+'.js'
              ]
            css_bower: (src) ->
              grunt.file.expand cwd: 'dist', [
                'assets/bower/**/*.css'
              ]
            js_bower: (src) ->
              grunt.file.expand cwd: 'dist', [
                'assets/bower/**/*.js'
              ]
          for namespace of files
            type = namespace.split('_')[0]
            itype = namespace.split('_')[1]

            do(namespace, type, itype, file) ->
              res[namespace] = (src) ->
                r = ''
                obj[namespace] ?= {}
                obj[namespace].exclude ?= []
                obj[namespace].files = files[namespace](src)
                for ex in obj[namespace].exclude
                  index = obj[namespace].files.indexOf ex
                  obj[namespace].files.splice index, 1 unless index == -1
                unless src?
                  for nfile in obj[namespace].files
                    r += util.format template[type], nfile
                  return r

                pre = ''
                nope = src[0] == '!'
                obj[namespace].files = obj[namespace].files.filter minimatch.filter (if -1 == src.indexOf after then '!' else '')+'assets/scripts/*/' + after + '/**/*.js', {}
                src += '/**/*.'+type unless src.endsWith '.'+type
                src = src.slice 1 if nope


                switch type
                  when 'js'
                    pre += 'assets/scripts/'
                  when 'css'
                    pre += 'assets/styles/'

                pre += 'assets/' + itype + '/' if itype?

                exclude = obj[namespace].files.filter minimatch.filter pre+'*.'+type, {}
                exdynamic = obj[namespace].files.filter minimatch.filter pre+src, {}

                for ex in exdynamic
                  exclude.push ex if -1 == exclude.indexOf ex
                for ex in exclude
                  index = obj[namespace].files.indexOf ex
                  entry = obj[namespace].files.splice index, 1
                  unless nope
                    obj[namespace].exclude.push entry[0]
                    r += util.format template[type], entry[0]
                return r
          res


      files: [
        expand: true
        cwd: 'src/templates'
        src: [ '**/*.pug' ]
        dest: 'dist'
        ext: '.html'
      ]

    stylus: compile:
      options:
        compress: false
        import: [ 'nib' ]
      files: [
        expand: true
        cwd: 'src/styles'
        src: [ '**/*.styl' ]
        dest: 'dist/assets/styles'
        ext: '.css'
      ]

    watch:
      scripts:
        files: [ '<%= coffee.compile.files[0].cwd %>/<%= coffee.compile.files[0].src %>' ]
        tasks: [ 'newer:coffee' ]
        options: spawn: true
      styles:
        files: [ '<%= stylus.compile.files[0].cwd %>/<%= stylus.compile.files[0].src %>' ]
        tasks: [ 'newer:stylus' ]
        options: spawn: true
      templates:
        files: [ '<%= pug.compile.files[0].cwd %>/<%= pug.compile.files[0].src %>' ]
        tasks: [ 'newer:pug' ]
        options: spawn: true
      bower:
        files: [ 'bower_components/*' ]
        tasks: [ 'bower' ]
        options: spawn: false

    bower: dev:
      dest: 'dist/assets/bower/'
      options:
        expand: true
        keepExpandedHierarchy: false

    copy: dev: files: [
      expand: true
      cwd: 'src/assets'
      src: [ '**' ]
      dest: 'dist/assets'
    ]



    modify_json: bower:
      options:
        add: true
        indent: '  '
        fields:
          name: json.name
          version: json.version
          description: json.description
          repository: json.repository
          keywords: json.keywords
          authors: json.authors
          license: json.license
          homepage: json.homepage
      files: src: [ 'bower.json' ]

    clean: dev: src: [ 'dist' ]

  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-stylus'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-contrib-clean'
  grunt.loadNpmTasks 'grunt-contrib-copy'
  grunt.loadNpmTasks 'grunt-contrib-pug'
  grunt.loadNpmTasks 'grunt-modify-json'
  grunt.loadNpmTasks 'grunt-bower'
  grunt.loadNpmTasks 'grunt-newer'

  grunt.registerTask 'default', [
    'clean'
    'newer:modify_json'
    'copy'
    'bower'
    'coffee'
    'stylus'
    'pug'
    'watch'
  ]
