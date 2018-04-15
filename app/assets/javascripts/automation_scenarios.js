document.addEventListener("turbolinks:load", function() {
    //Functions
    function buildSolutionGraphLinesFromSolutionsArray(savedSolutionsJSONArray){
        var solutionAxis = [];

        savedSolutionsJSONArray.forEach(function(solutionJson){
            solutionAxis.push(buildGraphLineFromSolution(solutionJson.initial_cost, solutionJson.iteration_cost, solutionJson.iteration_count));
        });

        return solutionAxis;
    }

    function buildGraphLineFromSolution(initialCost, costPerIteration, iterationCount){
        var xAxisPoints = [];
        var yAxisPoints = [];
        for (i = 1; i <= Number(iterationCount); i++) {
            xAxisPoints.push(i);
            yAxisPoints.push(Number(initialCost)+(Number(i)*Number(costPerIteration)));
        }
        return {x:xAxisPoints, y:yAxisPoints, type: 'scatter'};
    }

    function buildSavedSolutionsJSONArray(){
        return JSON.parse($('#scenarioSolutions').text());
    }

    //Execution
    Plotly.newPlot('solutionsChart', buildSolutionGraphLinesFromSolutionsArray(buildSavedSolutionsJSONArray()));
});