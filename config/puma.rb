# Puma can serve each request in a thread from an internal thread pool.
# The `threads` method setting takes two numbers: a minimum and maximum.
# Any libraries that use thread pools should be configured to match
# the maximum value specified for Puma. Default is set to 5 threads for minimum
# and maximum; this matches the default thread size of Active Record.
#
max_threads_count = ENV.fetch('RAILS_MAX_THREADS', 5)
min_threads_count = ENV.fetch('RAILS_MIN_THREADS') { max_threads_count }
threads min_threads_count, max_threads_count

# Specifies the `port` that Puma will listen on to receive requests;
# default is 3000.
#
# The host is pinned to the IPv4 wildcard. Puma 8 changed its default bind
# from 0.0.0.0 to :: (IPv6) whenever the host has a non-loopback IPv6
# interface; the Helm probes, the ALB target group and the docker-compose
# port mapping all reach the container over IPv4, so keep the pre-8
# behaviour explicit rather than depending on the pod's interface list.
#
port ENV.fetch('RAILS_SERVER_PORT', 3000), '0.0.0.0'

# Specifies the `environment` that Puma will run in.
#
environment ENV.fetch('RAILS_ENV') { 'development' }

# Specifies the number of `workers` to boot in clustered mode.
# Workers are forked web server processes. If using threads and workers together
# the concurrency of the application would be max `threads` * `workers`.
# Workers do not work on JRuby or Windows (both of which do not support
# processes).
#
# workers ENV.fetch("WEB_CONCURRENCY") { 2 }

# Use the `preload_app!` method when specifying a `workers` number.
# This directive tells Puma to first boot the application and load code
# before forking the application. This takes advantage of Copy On Write
# process behavior so workers use less memory. Since puma 7 it is the
# default in clustered mode, and the worker lifecycle hooks are named
# `before_worker_boot` / `before_worker_shutdown` (the `on_*` names from
# puma 5 were removed).
#
# preload_app!

# Allow puma to be restarted by `rails restart` command.
plugin :tmp_restart
