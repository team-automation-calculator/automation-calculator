// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, or any plugin's
// vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require rails-ujs
//= require turbolinks
//= require jquery
//= require popper
//= require bootstrap
//= require jquery.validate.min
//= require_tree .

$( document ).on('turbolinks:load', function() {
  // Javascript method's body can be found in assets/js/demos.js
  demo.initDashboardPageCharts();
  $("#new_session").validate({
    errorElement: 'span',
    errorClass: 'desc',
    rules: {
      "user[password]": {
        required: true
      },
      "user[email]": {
        required: true,
        email: true
      }
    },
    messages: {
      "user[email]": {
        required: "We need your email address to login.",
        email: "Your email address must be in the format of name@domain.com."
      },
      "user[password]": {
        required: "We need your password to login.",
      }
    },
  });
  $("#new_user_registration").validate({
    errorElement: 'span',
    errorClass: 'desc',
    rules: {
      "user[password]": {
        required: true
      },
      "user[password_confirmation]": {
        required: true,
        equalTo : "#password"
      },
      "user[email]": {
        required: true,
        email: true
      }
    },
    messages: {
      "user[email]": {
        required: "We need your email address for sign up.",
        email: "Your email address must be in the format of name@domain.com"
      },
      "user[password]": {
        required: "We need your password for sign up."
      },
       "user[password_confirmation]": {
        required: "We need your password confirmation as you set password field for sign up."
      }
    },
  });
});