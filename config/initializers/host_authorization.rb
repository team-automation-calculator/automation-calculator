require 'allowed_hosts'

# ActionDispatch::HostAuthorization answers 403 to any request whose
# Host or X-Forwarded-Host is not in config.hosts, before a controller
# runs. The ALB already 404s a forged Host, but it passes
# X-Forwarded-Host through untouched, and Rails builds absolute URLs
# (redirect_to, url_for, the OmniAuth failure redirect) from that
# header.
#
# In production an unset APP_HOSTNAME leaves the list empty, which this
# middleware treats as "no restriction": every request passes, as it
# did before this initializer. (OmniAuth treats the same empty list as
# "reject every OAuth request", see config/initializers/omniauth.rb.)
#
# The Kubernetes liveness and readiness probes and the ALB target-group
# health check all hit the pod directly, http://<pod-ip>:3000/health,
# with the pod IP as the Host header (core-iac:
# helm/automation-calculator/templates/deployment.yaml and the
# alb.ingress.kubernetes.io/healthcheck-path annotation in the chart
# values). /health is excluded from the host check so those probes keep
# getting 200; without the exclusion every probe gets a 403 and the
# deployment crashloops.
Rails.application.configure do
  config.hosts = AllowedHosts.list
  config.host_authorization = {
    exclude: ->(request) { request.path == '/health' }
  }
end
