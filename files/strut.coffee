[MAX_X, MAX_Y] = [12, 12]
DIAMETER = 1 / 8
FEED_RATE = 30

svg = d3.select '#preview'
  .attr 'viewBox', "0 0 #{MAX_X} #{MAX_Y}"
  .append 'g'
  .attr 'transform', "translate(0, #{MAX_Y}) scale(1, -1)"

do -> # add grid
  for y in [1 ... Math.ceil(MAX_Y)]
    for x in [1 ... Math.ceil(MAX_X)]
      svg.append 'circle'
        .attr 'class', 'grid'
        .attr 'cx', x
        .attr 'cy', y
        .attr 'r', DIAMETER / 3

commands = do ->
  [x, y] = [MAX_X / 2, MAX_Y / 2]
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
    .attr 'stroke-width', DIAMETER / 4

  gcode = d3.select('#gcode')

  pointsToPathData = (points) ->
    "M #{points}"

  pointsToGcode = (points) ->
    lines = for point in points
      "G1 X#{point[0].toFixed(3)} Y#{point[1].toFixed(3)} F#{FEED_RATE}"
    lines.join('\n')

  update: ->
    marker
      .attr 'cx', x
      .attr 'cy', y
    path
      .attr 'd', pointsToPathData(history)
    gcode.text pointsToGcode(history)
    history.length

  moveForward: (distance = 1) ->
    x += distance * Math.cos(heading)
    y += distance * Math.sin(heading)
    history.push [x, y]
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
      return function(MAX_X, MAX_Y, DIAMETER, moveForward, turnLeft, turnRight, currentX, currentY, currentHeading) {
        var state = {};
        return function() {
          #{js}
        };
      };
    })()
    """
  { moveForward, turnLeft, turnRight, currentX, currentY, currentHeading } = commands
  step = doRun? MAX_X, MAX_Y, DIAMETER, moveForward, turnLeft, turnRight, currentX, currentY, currentHeading
  setInterval ->
    step()
    commands.update()
  , 50

d3.select('#run').on 'click', ->
  run d3.select('#input').property('value')

d3.select('#input').property 'value',
  """
  var key = (currentX().toFixed(3)) + " " + (currentY().toFixed(3));

  if (state[key]) {
    turnLeft();
    delete state[key];
  } else {
    turnRight();
    state[key] = true;
  }
  moveForward(DIAMETER);
  """
