document.addEventListener("turbolinks:load", function() {
  var data = [];
  var number_pattern = /^[1-9!*?]/;
  var real_number_alert_string = 'Value must be a number greater than 0.';
  var alert_string_preface = 'Enter a valid';

  function buildValidRealNumberAlertMessage(name){
      return alert_string_preface+' '+name+'. '+real_number_alert_string;
  }

  function buildAxisArray(initial_cost, cost_per_iteration, iterations){
      var x_axis = [];
      var y_axis = [];
      for (i = 1; i <= iterations; i++) {
          x_axis.push(i);
          y_axis.push(Number(initial_cost)+(Number(i)*Number(cost_per_iteration)));
      }
      return {"xAxis":x_axis, "yAxis":y_axis};
  }

  $('.render-chart').click(function(){
      var initial_cost = $('#initial_cost').val();
      var cost_per_iteration = $('#cost_per_iteration').val();
      var iterations = $('#iterations').val();

      var is_valid_initial_cost = number_pattern.test(initial_cost);
      var is_valid_cost_per_iteration = number_pattern.test(cost_per_iteration);
      var is_valid_iterations = number_pattern.test(iterations);

      if(is_valid_initial_cost === false) {
          alert(buildValidRealNumberAlertMessage('initial cost'));
          return false;
      }

      if(is_valid_cost_per_iteration === false) {
          alert(buildValidRealNumberAlertMessage('cost per iteration'));
          return false;
      }

      if(is_valid_iterations === false) {
          alert(buildValidRealNumberAlertMessage('iteration number'));
          return false;
      }

      var axis_array = buildAxisArray(initial_cost, cost_per_iteration, iterations);

      var trace = {
          x: axis_array.xAxis,
          y: axis_array.yAxis,
          type: 'scatter'
      };

      data.push(trace);
      Plotly.newPlot('renderChart', data);
      $('#chart-form')[0].reset();
      $(this).text('Add new line')
  });
});