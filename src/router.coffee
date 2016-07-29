fs = require('fs')
coffee = require('coffee-script')

router = (processors) ->
  { coffee } = processors

  routes =
    '/': { file: 'index.html' }
    '/strut.js': { file: 'strut.coffee', processor: coffee }
    '/styles.css': { file: 'styles.css' }

  route: (url, callback) ->
    handler = routes[url]
    return callback() unless handler?

    { file, processor } = handler
    fs.readFile "./files/#{file}", 'utf8', (err, data) ->
      throw err if err?
      data = processor(data) if processor?
      callback(data)

module.exports = router
