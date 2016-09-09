[MAX_X, MAX_Y] = [12, 12]
DIAMETER = 1 / 16
FEED_RATE = 30
PLUNGE_RATE = 10

svg = d3.select '#preview'
  .attr 'viewBox', "0 0 #{MAX_X} #{MAX_Y}"

g = svg.append 'g'
  .attr 'transform', "translate(0, #{MAX_Y}) scale(1, -1)"

do -> # add grid
  for y in [1 ... Math.ceil(MAX_Y)]
    for x in [1 ... Math.ceil(MAX_X)]
      g.append 'circle'
        .attr 'class', 'grid'
        .attr 'cx', x
        .attr 'cy', y
        .attr 'r', DIAMETER / 3

gcode = d3.select('#gcode')

newAgent = ->
  state = {}
  [x, y] = [MAX_X * (Math.random() + 0.5) / 2, MAX_Y * (Math.random() + 0.5) / 2]
  heading = 2 * Math.PI * Math.random()
  down = false
  history = []

  path = g.append 'path'
    .attr 'class', 'path'
    .attr 'stroke-width', DIAMETER

  marker = g.append 'circle'
    .attr 'class', 'marker'
    .attr 'cx', x
    .attr 'cy', y
    .attr 'r', DIAMETER / 2
    .attr 'stroke-width', DIAMETER / 4

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

  state: ->
    state

  history: ->
    history

  update: ->
    marker
      .attr 'cx', x
      .attr 'cy', y
    path
      .attr 'd', pointsToPathData(history)
    gcode.text pointsToGcode(history)
    history.length

  remove: ->
    marker.remove()
    path.remove()

interval = null
stopRunning = ->
  d3.select('#run').style 'display', 'block'
  d3.select('#stop').style 'display', 'none'
  if interval?
    clearInterval(interval)
    interval = null

agent = null

run = (js) ->
  stopRunning()

  d3.select('#run').style 'display', 'none'
  d3.select('#stop').style 'display', 'block'
  d3.select('#reset').style 'display', 'block'

  doRun = eval """
    (function() {
      return function(state, MAX_X, MAX_Y, DIAMETER, moveForward, turnLeft, turnRight, raise, lower, currentX, currentY, currentHeading) {
        return function() {
          #{js}
        };
      };
    })()
    """
  { moveForward, turnLeft, turnRight, raise, lower, currentX, currentY, currentHeading } = agent
  step = doRun? agent.state(), MAX_X, MAX_Y, DIAMETER, moveForward, turnLeft, turnRight, raise, lower, currentX, currentY, currentHeading

  steps = 0
  interval = setInterval ->
    steps += 1
    try
      step() for i in [1 .. Math.sqrt(steps)]
    catch
      stopRunning()
    agent.update()
  , 50

reset = ->
  stopRunning()
  agent?.remove()
  agent = newAgent()
  agent.update()
  d3.select('#reset').style 'display', 'none'

d3.select('#run').on 'click', ->
  run d3.select('#input').property('value')

d3.select('#stop').on 'click', stopRunning

d3.select('#reset').on 'click', reset

reset()

EXAMPLE =
  ant: """
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
  gravity: """
    state.dt = state.dt || 1;
    state.t = (state.t || 0) + state.dt;
    state.speed = state.speed || 0;
    state.attractors = [
      { x: 5, y: 3, G: 0.004 },
      { x: 5, y: 5, G: 0.0004 },
    ];

    var a = { x: 0, y: 0 };
    state.attractors.forEach(function(p) {
      var dx = p.x - currentX();
      var dy = p.y - currentY();
      var d = Math.hypot(dy, dx);
      a.x += state.dt * p.G * (dx / d) / Math.pow(d, 2);
      a.y += state.dt * p.G * (dy / d) / Math.pow(d, 2);
    });

    var v = { x: state.speed * Math.cos(currentHeading()), y: state.speed * Math.sin(currentHeading()) };
    var v2 = { x: v.x + a.x, y: v.y + a.y };
    var dt = 1 / 16;
    state.speed = Math.hypot(v2.y, v2.x);
    state.dt = dt;

    lower();
    turnLeft(Math.atan2(v2.y, v2.x) - Math.atan2(v.y, v.x));
    moveForward(Math.hypot(dt * v.y, dt * v.x));
    """
  star:
    """
    var POINTS = [
      { x: 2, y: 1 },
      { x: 6, y: 3 },
      { x: 10, y: 1 },
      { x: 9, y: 4.5 },
      { x: 11.5, y: 7 },
      { x: 8, y: 7.5 },
      { x: 6, y: 11 },
      { x: 4, y: 7.5 },
      { x: 0.5, y: 7 },
      { x: 3, y: 4.5 },
    ];
    var SEGMENTS = [];
    for (var index = 0; index < POINTS.length; index++) {
      SEGMENTS.push({ p1: POINTS[index], p2: POINTS[(index + 1) % POINTS.length] });
    }
    // http://bryceboe.com/2006/10/23/line-segment-intersection-algorithm/
    var ccw = function(A, B, C) {
      return (C.y - A.y) * (B.x - A.x) > (B.y - A.y) * (C.x - A.x);
    };
    var intersect = function(A, B, C, D) {
      return ccw(A, C, D) !== ccw(B, C, D) && ccw(A, B, C) !== ccw(A, B, D);
    };
    var hit = false;
    SEGMENTS.forEach(function(s) {
      var p1 = { x: currentX(), y: currentY() };
      var v = { x: DIAMETER * Math.cos(currentHeading()), y: DIAMETER * Math.sin(currentHeading()) };
      var p2 = { x: p1.x + v.x, y: p1.y + v.y };
      var incidenceAngle = currentHeading();
      var segmentAngle = Math.atan2(s.p2.y - s.p1.y, s.p2.x - s.p1.x);
      var ss = Math.hypot(s.p2.y - s.p1.y, s.p2.x - s.p1.x);
      if (intersect(p1, p2, s.p1, s.p2)) {
        var rejectionAngle = Math.atan2(v.y / DIAMETER - Math.cos(segmentAngle - incidenceAngle) * (s.p2.y - s.p1.y) / ss, v.x / DIAMETER - Math.cos(segmentAngle - incidenceAngle) * (s.p2.x - s.p1.x) / ss);
        var resultAngle = Math.PI + 2 * rejectionAngle - incidenceAngle;
        turnLeft(resultAngle - incidenceAngle);
        hit = true;
      }
    });

    if (!hit) {
      lower();
      moveForward(DIAMETER);
    }
    """

applySelectedExample = ->
  example = d3.select('#example').property('value')
  d3.select('#input').property 'value', EXAMPLE[example]

d3.select('#example').on 'change', applySelectedExample

applySelectedExample()
