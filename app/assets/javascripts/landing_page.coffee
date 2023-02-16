# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/


document.addEventListener 'turbolinks:load', ->
  #Variables
  scenario_title = 'Current Manual vs Future Automated Process'
  scenario_count = 100
  iteration_count_form_id = 'automation_scenario_iteration_count'
  scenario_title_form_id = 'automation_scenario_name'

  layout =
    hovermode:'closest'
    title: scenario_title

  exampleManualSolution =
    initial_cost: 0
    iteration_cost: 10
    iteration_count: scenario_count
    display_name: 'Current Manual Process'
    initial_cost_form_id: 'automation_scenario_manual_solution_initial_cost'
    iteration_cost_form_id: 'automation_scenario_manual_solution_iteration_cost'
    display_name_form_id: 'automation_scenario_manual_solution_name'
  
  exampleAutomatedSolution =
    initial_cost: 500
    iteration_cost: 0
    iteration_count: scenario_count
    display_name: 'Future Automated Process'
    initial_cost_form_id: 'automation_scenario_automated_solution_initial_cost'
    iteration_cost_form_id: 'automation_scenario_automated_solution_iteration_cost'
    display_name_form_id: 'automation_scenario_automated_solution_name'
  
  exampleSolutions = [
    exampleManualSolution,
    exampleAutomatedSolution
  ]

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
  
  buildPlotFromExampleData = (target_div) ->
    Plotly.newPlot(
      target_div, buildSolutionGraphLinesFromSolutionsArray(exampleSolutions), layout
    )
  
  setScenarioIterationCountFromFormValue = (form_id) -> 
    scenario_count = document.getElementById(form_id).value
    exampleManualSolution.iteration_count = scenario_count
    exampleAutomatedSolution.iteration_count = scenario_count
  
  setScenarioTitleFromFormValue = (form_id) ->
    scenario_title = document.getElementById(form_id).value
    layout.title = scenario_title
  
  setExampleInitialCost = (solution, form_id) ->
    solution.initial_cost = document.getElementById(form_id).value

  setExampleIterationCost = (solution, form_id) ->
    solution.iteration_cost = document.getElementById(form_id).value

  setExampleName = (solution, form_id) ->
    solution.display_name = document.getElementById(form_id).value  
  
  #Execution
  setScenarioIterationCountFromFormValue(iteration_count_form_id)
  setScenarioTitleFromFormValue(scenario_title_form_id)

  exampleSolutions.forEach (solution) ->
    #Ensure solution iteration count is set to scenario_count
    solution.iteration_count = scenario_count
    #Set solution form values, keeping them if page is refreshed/back button is used
    setExampleInitialCost(solution, solution.initial_cost_form_id)
    setExampleIterationCost(solution, solution.iteration_cost_form_id)
    setExampleName(solution, solution.display_name_form_id)
    #Add event listeners to update graph when form values are changed
    document.getElementById(solution.initial_cost_form_id).addEventListener 'change', (event) ->
      setExampleInitialCost(solution, solution.initial_cost_form_id)
      buildPlotFromExampleData(plotly_div_id)
    document.getElementById(solution.iteration_cost_form_id).addEventListener 'change', (event) ->
      setExampleIterationCost(solution, solution.iteration_cost_form_id)
      buildPlotFromExampleData(plotly_div_id)
    document.getElementById(solution.display_name_form_id).addEventListener 'change', (event) ->
      setExampleName(solution, solution.display_name_form_id)
      buildPlotFromExampleData(plotly_div_id)
  
  #Build inital plot
  buildPlotFromExampleData(plotly_div_id)

  document.getElementById(iteration_count_form_id).addEventListener 'change', (event) ->
    setScenarioIterationCountFromFormValue(iteration_count_form_id)
    buildPlotFromExampleData(plotly_div_id)
  
  document.getElementById(scenario_title_form_id).addEventListener 'change', (event) ->
    setScenarioTitleFromFormValue(scenario_title_form_id)
    buildPlotFromExampleData(plotly_div_id)
