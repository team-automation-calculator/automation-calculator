# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/


document.addEventListener 'turbolinks:load', ->
  #Variables
  scenario_count = 100

  exampleManualSolution =
    initial_cost: 5
    iteration_cost: 10
    iteration_count: scenario_count
    display_name: 'Current Manual Process'
  
  exampleAutomatedSolution =
    initial_cost: 100
    iteration_cost: 1
    iteration_count: scenario_count
    display_name: 'Future Automated Process'
  
  exampleSolutions = [
    exampleManualSolution,
    exampleAutomatedSolution
  ]
  
  #Functions
  buildSolutionGraphLinesFromSolutionsArray = (solutions) ->
    solutionPoints = []
    solutions.forEach (solution) ->
      solutionPoints.push(
        buildGraphLineFromSolutionObject(solution)
      )
    solutionPoints
  
  buildGraphLineFromSolutionObject = (solution) ->
    buildGraphLineFromSolution(
      solution.initial_cost,
      solution.iteration_cost,
      solution.iteration_count,
      solution.display_name
    )

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

  #Execution
  layout =
    hovermode:'closest'
    title: 'test'

  Plotly.newPlot(
    'solutionsChart', buildSolutionGraphLinesFromSolutionsArray(exampleSolutions), layout
  )
