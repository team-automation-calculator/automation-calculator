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
  manual_solution_initial_cost_form_id = 'automation_scenario_manual_solution_initial_cost'
  manual_solution_iteration_cost_form_id = 'automation_scenario_manual_solution_iteration_cost'
  second_solution_initial_cost_form_id = 'automation_scenario_second_solution_initial_cost'
  second_solution_iteration_cost_form_id = 'automation_scenario_second_solution_iteration_cost'
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
  
  setExampleInitialCost = (solution, form_id) ->
    solution.initial_cost = document.getElementById(form_id).value

  setExampleIterationCost = (solution, form_id) ->
    solution.iteration_cost = document.getElementById(form_id).value  
  
  buildPlotFromExampleData = (target_div) ->
    Plotly.newPlot(
      target_div, buildSolutionGraphLinesFromSolutionsArray(exampleSolutions), layout
    )

  #Execution
  layout =
    hovermode:'closest'
    title: 'Current Manual vs Future Automated Process'

  setExampleIterationCountFromFormValue(iteration_count_form_id)
  setExampleInitialCost(exampleManualSolution, manual_solution_initial_cost_form_id)
  setExampleIterationCost(exampleManualSolution, manual_solution_iteration_cost_form_id)
  setExampleInitialCost(exampleAutomatedSolution, second_solution_initial_cost_form_id)
  setExampleIterationCost(exampleAutomatedSolution, second_solution_iteration_cost_form_id)
  buildPlotFromExampleData(plotly_div_id)

  document.getElementById(iteration_count_form_id).addEventListener 'change', (event) ->
    setExampleIterationCountFromFormValue(iteration_count_form_id)
    buildPlotFromExampleData(plotly_div_id)
  
  document.getElementById(manual_solution_initial_cost_form_id).addEventListener 'change', (event) ->
    setExampleInitialCost(exampleManualSolution, manual_solution_initial_cost_form_id)
    buildPlotFromExampleData(plotly_div_id)

  document.getElementById(manual_solution_iteration_cost_form_id).addEventListener 'change', (event) ->
    setExampleIterationCost(exampleManualSolution, manual_solution_iteration_cost_form_id)
    buildPlotFromExampleData(plotly_div_id)
  
  document.getElementById(second_solution_initial_cost_form_id).addEventListener 'change', (event) ->
    setExampleInitialCost(exampleAutomatedSolution, second_solution_initial_cost_form_id)
    buildPlotFromExampleData(plotly_div_id)
  
  document.getElementById(second_solution_iteration_cost_form_id).addEventListener 'change', (event) ->
    setExampleIterationCost(exampleAutomatedSolution, second_solution_iteration_cost_form_id)
    buildPlotFromExampleData(plotly_div_id)
