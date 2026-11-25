require 'active_support/log_subscriber'

# Action Mailer's own log subscriber writes every outgoing message in full
# at debug level, and production logs at debug by default. The only mail
# this app sends is Devise's password-reset instructions, so that put the
# recipient's address and a working reset link (valid for
# config.reset_password_within) in the pod log: anyone who can read logs
# could take over any account by requesting a reset for it.
#
# This subscriber replaces it (config/initializers/mail_logging.rb) and
# writes the same lines minus the message itself.
class MailLogSubscriber < ActiveSupport::LogSubscriber
  def deliver(event)
    info { delivery_line(event) }
  end
  subscribe_log_level :deliver, :info

  def process(event)
    debug do
      payload = event.payload
      "#{payload[:mailer]}##{payload[:action]}: processed outbound mail " \
        "in #{event.duration.round(1)}ms"
    end
  end
  subscribe_log_level :process, :debug

  # Use the logger configured for ActionMailer::Base.
  delegate :logger, to: 'ActionMailer::Base'

  private

  def delivery_line(event)
    payload = event.payload
    id = payload[:message_id]
    if (error = payload[:exception_object])
      "Failed delivery of mail #{id} error_class=#{error.class} " \
        "error_message=#{error.message.inspect}"
    elsif payload[:perform_deliveries]
      "Delivered mail #{id} (#{event.duration.round(1)}ms)"
    else
      "Skipped delivery of mail #{id} as `perform_deliveries` is false"
    end
  end
end
