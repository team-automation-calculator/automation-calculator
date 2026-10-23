require 'allowed_hosts'

# omniauth 2.3 builds each provider's redirect_uri from the request's
# host, which comes from the Host or X-Forwarded-Host header. With
# allowed_hosts set, a request whose host is not listed fails with
# :invalid_host (Devise then runs Users::OmniauthCallbacksController#failure,
# a 302 to /) before the authorize URL is built, so a forged host never
# reaches the provider. Without it, OmniAuth trusts the header and warns
# on every POST /users/auth/:provider.
#
# The list is the one Rails host authorization uses
# (config/initializers/host_authorization.rb), so in practice that
# middleware answers a forged host with 403 before OmniAuth sees it;
# this is the second line. The two read the empty list differently: an
# unset APP_HOSTNAME in production makes Rails pass every host, while
# OmniAuth rejects every OAuth request rather than trust the header.
OmniAuth.config.allowed_hosts = AllowedHosts.list
