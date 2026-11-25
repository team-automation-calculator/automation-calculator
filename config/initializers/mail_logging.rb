require 'action_mailer/log_subscriber'
require 'mail_log_subscriber'

# Keep message bodies (password-reset links) and recipient addresses out
# of the log in every environment; see lib/mail_log_subscriber.rb.
# Development opens mail in the browser (letter_opener) and does not need
# the dump either.
ActionMailer::LogSubscriber.detach_from :action_mailer
MailLogSubscriber.attach_to :action_mailer
