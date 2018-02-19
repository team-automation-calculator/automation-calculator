document.addEventListener("turbolinks:load", function() {
  var data = [];
  var number_pattern = /^[1-9!,*?]/
  $('.render-chart').click(function(){
    var x_axis = $('#x-axis').val();
    var y_axis = $('#y-axis').val();
    var x = x_axis.split(",").map(Number)
    var y = y_axis.split(",").map(Number)

    var is_valid_x = number_pattern.test(x_axis)
    var is_valid_y = number_pattern.test(y_axis)

    if(is_valid_x == false || is_valid_y == false){
      alert('Enter Valid Axis. Value should be greater than 0')
      return false;
    }

    var trace = {
      x: x,
      y: y,
      type: 'scatter'
    }
    data.push(trace)
    Plotly.newPlot('renderChart', data);
    $('#chart-form')[0].reset();
    $(this).text('Add new line')
  });
});