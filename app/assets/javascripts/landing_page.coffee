# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/


document.addEventListener 'turbolinks:load', ->
  #Variables
  exampleSolution =
    initial_cost: 5
    iteration_cost: 10
    iteration_count: 10
    display_name: 'Sample Line'

  
  #Execution
  if savedScenarioData().solutions
    buildPlotlyPlotFromSavedScenarios(savedScenarioData())

  layout =
    hovermode:'closest'
    title: savedScenarioData().display_name

  Plotly.newPlot(
    'solutionsChart', [], layout
  )
