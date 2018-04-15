document.addEventListener("turbolinks:load", function() {
  $('.test-button').click(function () {
      console.log("You clicked test button!");
  }),

  $('.render-chart').click(function () {
      console.log("You clicked a paragraph!");
  })
});