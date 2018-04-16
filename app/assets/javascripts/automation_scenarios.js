document.addEventListener('turbolinks:load', function() {
    //Variables
    var exampleSolutionJson = {
        initial_cost: 5,
        iteration_cost: 10,
        iteration_count: 10
    };

    //Functions
    function buildSolutionGraphLinesFromSolutionsArray(savedSolutionsJSONArray){
        var solutionAxis = [];

        if(savedSolutionsJSONArray.length > 0) {
            savedSolutionsJSONArray.forEach(function(solutionJson){
                solutionAxis.push(buildGraphLineFromSolution(
                    solutionJson.initial_cost,
                    solutionJson.iteration_cost,
                    solutionJson.iteration_count));
            });
        } else {
            //Example graph line here
            solutionAxis.push(buildGraphLineFromSolution(
                exampleSolutionJson.initial_cost,
                exampleSolutionJson.iteration_cost,
                exampleSolutionJson.iteration_count));
        }

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
    if (document.getElementById('scenarioSolutions')) {
        Plotly.newPlot('solutionsChart', buildSolutionGraphLinesFromSolutionsArray(buildSavedSolutionsJSONArray()));
    }
});