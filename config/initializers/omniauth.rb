# omniauth 2.3 builds each provider's redirect_uri from the request's
# host, which comes from the Host or X-Forwarded-Host header. With
# allowed_hosts set, a request whose host is not listed fails with
# :invalid_host (Devise then runs Users::OmniauthCallbacksController#failure,
# a 302 to /) before the authorize URL is built, so a forged host never
# reaches the provider. Without it, OmniAuth trusts the header and warns
# on every POST /users/auth/:provider.
#
# Deployed environments run as production with APP_HOSTNAME set by the
# core-iac Helm chart from the ingress host, which also routes the www
# alias. An unset APP_HOSTNAME leaves the list empty, which rejects every
# OAuth request rather than trusting the header. Everywhere else: the
# host-mapped dev server, the compose service name (./go smoke), and the
# host Rails integration tests and Capybara's rack_test driver use.
OmniAuth.config.allowed_hosts =
  if Rails.env.production?
    host = ENV['APP_HOSTNAME'].to_s
    host.empty? ? [] : [host, "www.#{host}"]
  else
    %w[localhost 127.0.0.1 dev www.example.com]
  end
