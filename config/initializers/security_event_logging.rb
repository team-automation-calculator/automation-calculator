# Security-relevant events that Rails, Devise and Warden handle without
# writing a log line of their own. Each line names the user by id, never
# by email, and carries the client address so a burst from one source
# stands out.

# rate_limit (Rails 8.1) instruments a throttled request but nothing
# subscribes to it by default: the client gets a 429 and the log shows
# only the status. The event fires only for requests over the limit.
ActiveSupport::Notifications.subscribe(
  'rate_limit.action_controller'
) do |event|
  payload = event.payload
  request = payload[:request]
  Rails.logger.warn(
    "Rate limit exceeded: #{request.request_method} #{request.path} " \
    "count=#{payload[:count]} limit=#{payload[:to]}/" \
    "#{payload[:within].to_i}s by=#{payload[:by]}"
  )
end

# A web sign-in (password, OAuth, or the automatic one after sign-up).
# :fetch is the per-request session lookup, not a sign-in.
Warden::Manager.after_set_user except: :fetch do |user, auth, opts|
  ip = ActionDispatch::Request.new(auth.env).remote_ip
  Rails.logger.info(
    "Sign-in: #{opts[:scope]}=#{user.id} event=#{opts[:event]} ip=#{ip}"
  )
end

Warden::Manager.before_logout do |user, auth, opts|
  next unless user

  ip = ActionDispatch::Request.new(auth.env).remote_ip
  Rails.logger.info("Sign-out: #{opts[:scope]}=#{user.id} ip=#{ip}")
end

# Warden fails a request both when submitted credentials are wrong (a
# POST: warn) and when a signed-out browser opens a protected page (a
# redirect to the sign-in form: info). Devise runs in paranoid mode, so
# the reason for a wrong email and a wrong password is the same.
Warden::Manager.before_failure do |env, opts|
  request = ActionDispatch::Request.new(env)
  reason = opts[:message] || env['warden']&.message || :unauthenticated
  Rails.logger.public_send(
    request.post? ? :warn : :info,
    "Authentication failed: scope=#{opts[:scope]} reason=#{reason} " \
    "#{request.request_method} #{opts[:attempted_path] || request.path} " \
    "ip=#{request.remote_ip}"
  )
end
