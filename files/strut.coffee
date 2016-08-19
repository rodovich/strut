[MAX_X, MAX_Y] = [12, 12]
DIAMETER = 1 / 16
FEED_RATE = 30
PLUNGE_RATE = 10

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
  down = false
  history = []

  pointsToPathData = (points) ->
    return '' if points.length is 0
    subpaths = ("M #{subsequence}" for subsequence in points)
    subpaths.join(' ')

  pointsToGcode = (points) ->
    lines = []
    for subsequence in points
      point = subsequence[0]
      lines.push "G0 X#{point[0].toFixed(3)} Y#{point[1].toFixed(3)}"
      lines.push "G1 Z0 F#{PLUNGE_RATE}"
      for point in subsequence[1...]
        lines.push "G1 X#{point[0].toFixed(3)} Y#{point[1].toFixed(3)} F#{FEED_RATE}"
      lines.push "G0 Z0.25"
    lines.join('\n')

  path = svg.append 'path'
    .attr 'class', 'path'
    .attr 'd', pointsToPathData(history)
    .attr 'stroke-width', DIAMETER

  marker = svg.append 'circle'
    .attr 'class', 'marker'
    .attr 'cx', x
    .attr 'cy', y
    .attr 'r', DIAMETER / 2
    .attr 'stroke-width', DIAMETER / 4

  gcode = d3.select('#gcode')

  update: ->
    marker
      .attr 'cx', x
      .attr 'cy', y
    path
      .attr 'd', pointsToPathData(history)
    gcode.text pointsToGcode(history)
    history.length

  raise: ->
    down = false

  lower: ->
    unless down
      down = true
      history.push [[x, y]]

  moveForward: (distance = DIAMETER) ->
    newX = x + distance * Math.cos(heading)
    newY = y + distance * Math.sin(heading)
    unless 0 <= newX <= MAX_X and 0 <= newY <= MAX_Y
      throw new Error("Exited at #{newX}, #{newY}")
    [x, y] = [newX, newY]
    if down
      history[history.length - 1].push [x, y]
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
      return function(MAX_X, MAX_Y, DIAMETER, moveForward, turnLeft, turnRight, raise, lower, currentX, currentY, currentHeading) {
        var state = {};
        return function() {
          #{js}
        };
      };
    })()
    """
  { moveForward, turnLeft, turnRight, raise, lower, currentX, currentY, currentHeading } = commands
  step = doRun? MAX_X, MAX_Y, DIAMETER, moveForward, turnLeft, turnRight, raise, lower, currentX, currentY, currentHeading

  steps = 0
  interval = setInterval ->
    steps += 1
    try
      step() for i in [1 .. Math.sqrt(steps)]
    catch
      clearInterval(interval)
      interval = null
    commands.update()
  , 50

d3.select('#run').on 'click', ->
  run d3.select('#input').property('value')

d3.select('#input').property 'value',
  """
  var N = 0, U = Math.PI,
    L1 = U / 3, L2 = 2 * L1,
    R1 = -L1, R2 = -L2;
  var STATES = [
    L1, L2, N, U, L2, L1, R2
  ];
  var key = currentX().toFixed(5) + ' ' + currentY().toFixed(5);

  var currentState = state[key] || 0;
  turnLeft(STATES[currentState]);
  state[key] = (currentState + 1) % STATES.length;

  lower();
  moveForward();
  """
