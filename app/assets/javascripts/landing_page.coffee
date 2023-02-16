# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/


document.addEventListener 'turbolinks:load', ->
  #Variables
  scenario_count = 100

  exampleManualSolution =
    initial_cost: 0
    iteration_cost: 10
    iteration_count: scenario_count
    display_name: 'Current Manual Process'
  
  exampleAutomatedSolution =
    initial_cost: 500
    iteration_cost: 0
    iteration_count: scenario_count
    display_name: 'Future Automated Process'
  
  exampleSolutions = [
    exampleManualSolution,
    exampleAutomatedSolution
  ]

  iteration_count_form_id = 'automation_scenario_iteration_count'
  plotly_div_id = 'solutionsChart'
  
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
  
  setExampleIterationCountFromFormValue = (form_id) -> 
    scenario_count = document.getElementById(form_id).value
    exampleManualSolution.iteration_count = scenario_count
    exampleAutomatedSolution.iteration_count = scenario_count
  
  buildPlotFromExampleData = (target_div) ->
    Plotly.newPlot(
      target_div, buildSolutionGraphLinesFromSolutionsArray(exampleSolutions), layout
    )


  #Execution
  layout =
    hovermode:'closest'
    title: 'Current Manual vs Future Automated Process'

  setExampleIterationCountFromFormValue(iteration_count_form_id)
  buildPlotFromExampleData(plotly_div_id)

  #Read value from form and update graph
  document.getElementById(iteration_count_form_id).addEventListener 'change', (event) ->
    setExampleIterationCountFromFormValue(iteration_count_form_id)
    Plotly.newPlot(
      plotly_div_id, buildSolutionGraphLinesFromSolutionsArray(exampleSolutions), layout
    )
