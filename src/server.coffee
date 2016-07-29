fs = require('fs')
http = require('http')
coffeescript = require('coffee-script')
router = require('./router')({ coffee: coffeescript.compile })

server = http.createServer (request, response) ->
  router.route request.url, (data) ->
    if data?
      response.end data
    else
      response.statusCode = 404
      response.end 'whoops'

PORT = process.argv[2] or 5888

server.listen PORT, ->
  console.log "strutting at http://localhost:#{PORT}/"
