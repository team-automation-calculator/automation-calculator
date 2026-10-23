# The hostnames this app answers to. One list feeds Rails host
# authorization (config/initializers/host_authorization.rb) and is the
# list OmniAuth.config.allowed_hosts should share, so the two never
# drift apart.
#
# Deployed environments run as production with APP_HOSTNAME set by the
# core-iac Helm chart from the ingress host, which also routes the www
# alias. An unset APP_HOSTNAME leaves the list empty. Everywhere else:
# the host-mapped dev server, the compose service name (./go smoke),
# and the host Rails integration tests and Capybara's rack_test driver
# use.
module AllowedHosts
  LOCAL = %w[localhost 127.0.0.1 dev www.example.com].freeze

  def self.list(production: Rails.env.production?,
                app_hostname: ENV['APP_HOSTNAME'])
    return LOCAL.dup unless production

    host = app_hostname.to_s
    host.empty? ? [] : [host, "www.#{host}"]
  end
end
