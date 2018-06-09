document.addEventListener 'turbolinks:load', ->
  #Variables
  exampleSolutionJson = 
    initial_cost: 5
    iteration_cost: 10
    iteration_count: 10
  #Execution
  #Functions

  buildSolutionGraphLinesFromSolutionsArray = (savedSolutionsJSONArray) ->
    solutionAxis = []
    if savedSolutionsJSONArray.length > 0
      savedSolutionsJSONArray.forEach (solutionJson) ->
        solutionAxis.push buildGraphLineFromSolution(solutionJson.initial_cost, solutionJson.iteration_cost, solutionJson.iteration_count)
        return
    else
      #Example graph line here
      solutionAxis.push buildGraphLineFromSolution(exampleSolutionJson.initial_cost, exampleSolutionJson.iteration_cost, exampleSolutionJson.iteration_count)
    solutionAxis

  buildGraphLineFromSolution = (initialCost, costPerIteration, iterationCount) ->
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
    }

  buildSavedSolutionsJSONArray = ->
    JSON.parse $('#scenarioSolutions').text()

  if document.getElementById('scenarioSolutions')
    Plotly.newPlot 'solutionsChart', buildSolutionGraphLinesFromSolutionsArray(buildSavedSolutionsJSONArray())
  return
