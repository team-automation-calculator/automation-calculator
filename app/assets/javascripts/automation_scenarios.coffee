document.addEventListener 'turbolinks:load', ->
  #Variables
  exampleSolution =
    initial_cost: 5
    iteration_cost: 10
    iteration_count: 10
    display_name: 'Sample Line'

  #Functions
  buildSolutionGraphLinesFromSolutionsArray = (savedSolutions) ->
    solutionPoints = []
    if savedSolutions.length > 0
      savedSolutions.forEach (solution) ->
        solutionPoints.push(
          buildGraphLineFromSolution(
            solution.initial_cost,
            solution.iteration_cost,
            solution.iteration_count,
            solution.display_name
          )
        )
        return
    else
      #Example graph line here
      solutionPoints.push(
        buildGraphLineFromSolution(
          exampleSolution.initial_cost,
          exampleSolution.iteration_cost,
          exampleSolution.iteration_count,
          exampleSolution.display_name
        )
      )
    solutionPoints

  buildGraphLineFromSolution = (initialCost, costPerIteration, iterationCount, name) ->
    xAxisPoints = []
    yAxisPoints = []
    i = 1
    while i <= Number(iterationCount)
      xAxisPoints.push i
      yAxisPoints.push Number(initialCost) + Number(i) * Number(costPerIteration)
      i++

    {
      x: xAxisPoints
      y: yAxisPoints
      type: 'scatter'
      name: name
    }

  buildIntersectionPoints = (intersectionsData) ->
    xPoints = []
    yPoints = []
    intersectionsData.forEach (intersection) ->
      xPoints.push intersection[0]
      yPoints.push intersection[1]

    {
      x: xPoints
      y: yPoints
      type: 'scatter'
      mode: 'markers'
      marker: { size: 8 }
      name: 'Intersections'
    }

  savedScenarioData = ->
    if document.getElementById('scenarioData')
      JSON.parse $('#scenarioData').text()
    else
      {}

  #Execution
  if savedScenarioData()
    layout =
      hovermode:'closest'
      title: savedScenarioData().display_name

    lines =
      buildSolutionGraphLinesFromSolutionsArray(
        savedScenarioData().solutions
      )
    lines.push(
       buildIntersectionPoints(savedScenarioData().intersections)
    )

    Plotly.newPlot(
      'solutionsChart', lines, layout
    )

  return
