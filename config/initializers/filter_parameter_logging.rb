# Be sure to restart your server when you modify this file.

# Configure parameters to be filtered from the log file. Use this to limit
# dissemination of sensitive information. See the ActiveSupport::ParameterFilter
# documentation for supported notations and behaviors.
Rails.application.config.filter_parameters += %i[
  passw email secret token _key crypt salt certificate otp ssn cvv cvc
]

# The OAuth callback (GET /users/auth/:provider/callback?code=…&state=…)
# carries the authorization code and the CSRF state in the query string,
# which Rails writes to the log in the "Started GET" line. Exact names
# only, so unrelated parameters that merely contain "code" stay readable.
Rails.application.config.filter_parameters += [/\Acode\z/, /\Astate\z/]
