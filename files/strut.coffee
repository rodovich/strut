[W, H] = [12, 12]
DIAMETER = 1 / 8

svg = d3.select '#preview'
  .attr 'viewBox', "0 0 #{W} #{H}"
  .append 'g'
  .attr 'transform', "translate(0, #{H}) scale(1, -1)"

do -> # add grid
  for y in [1 ... H]
    for x in [1 ... W]
      svg.append 'circle'
        .attr 'class', 'grid'
        .attr 'cx', x
        .attr 'cy', y
        .attr 'r', DIAMETER / 3

commands = do ->
  [x, y] = [1, 1]
  heading = 0
  history = [[x, y]]

  path = svg.append 'path'
    .attr 'class', 'path'
    .attr 'd', "M #{history}"
    .attr 'stroke-width', DIAMETER / 2

  marker = svg.append 'circle'
    .attr 'class', 'marker'
    .attr 'cx', x
    .attr 'cy', y
    .attr 'r', DIAMETER / 2

  moveForward: (distance = 1) ->
    x += distance * Math.cos(heading)
    y += distance * Math.sin(heading)
    history.push [x, y]
    marker
      .attr 'cx', x
      .attr 'cy', y
    path
      .attr 'd', "M #{history}"
    [x, y]

  turnLeft: (angle = Math.PI / 2) ->
    heading += angle

  turnRight: (angle = Math.PI / 2) ->
    heading -= angle

  currentX: ->
    x

  currentY: ->
    y

  currentHeading: ->
    heading

run = (js) ->
  doRun = eval """
    (function() {
      return function(moveForward, turnLeft, turnRight, currentX, currentY, currentHeading) {
        #{js}
      };
    })()
    """
  { moveForward, turnLeft, turnRight, currentX, currentY, currentHeading } = commands
  doRun? moveForward, turnLeft, turnRight, currentX, currentY, currentHeading

d3.select('#run').on 'click', ->
  run d3.select('#input').property('value')
