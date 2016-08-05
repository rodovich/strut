[W, H] = [12, 12]
RADIUS = 1 / 16

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
        .attr 'r', RADIUS * 2 / 3
