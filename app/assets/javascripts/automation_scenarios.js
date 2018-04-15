document.addEventListener("turbolinks:load", function() {
    //Functions
    function buildSolutionGraphLinesFromSolutionsArray(savedSolutionsJSONArray){
        var solutionAxis = [];

        savedSolutionsJSONArray.forEach(function(solutionJson){
            solutionAxis.push(buildGraphLineFromSolution(solutionJson.initial_cost, solutionJson.iteration_cost, solutionJson.iteration_count));
        });

        return solutionAxis;
    }

    function buildGraphLineFromSolution(initial_cost, cost_per_iteration, iterations){
        var xAxisPoints = [];
        var yAxisPoints = [];
        for (i = 1; i <= Number(iterations); i++) {
            xAxisPoints.push(i);
            yAxisPoints.push(Number(initial_cost)+(Number(i)*Number(cost_per_iteration)));
        }
        return {x:xAxisPoints, y:yAxisPoints, type: 'scatter'};
    }

    function buildSavedSolutionsJSONArray(){
        return JSON.parse($('#scenarioSolutions').text());
    }

    //Event Handlers
    $('.render-chart').click(function(){
        Plotly.newPlot('renderChart', buildSolutionGraphLinesFromSolutionsArray(buildSavedSolutionsJSONArray()));
    });

    //Execution
    buildSolutionGraphLinesFromSolutionsArray(buildSavedSolutionsJSONArray()).forEach(function(graphLine){
        console.log(graphLine);
    });
});