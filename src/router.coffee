fs = require('fs')
coffee = require('coffee-script')

router = (processors) ->
  { coffee } = processors

  routes =
    '/': { file: './files/index.html' }
    '/d3.js': { file: './node_modules/d3/build/d3.js' }
    '/strut.js': { file: './files/strut.coffee', processor: coffee }
    '/styles.css': { file: './files/styles.css' }

  route: (url, callback) ->
    handler = routes[url]
    return callback() unless handler?

    { file, processor } = handler
    fs.readFile file, 'utf8', (err, data) ->
      throw err if err?
      data = processor(data) if processor?
      callback(data)

module.exports = router
