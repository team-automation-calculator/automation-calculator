module Users
  class OmniauthCallbacksController < ::Devise::OmniauthCallbacksController
    def github
      sign_in_from_omniauth('GitHub')
    end

    def google_oauth2
      sign_in_from_omniauth('Google')
    end

    # The user is sent home without a message, so the log line is the only
    # record of why an OAuth sign-in failed: :invalid_host (forged Host
    # header), :csrf_detected or :invalid_credentials (state mismatch,
    # tampered or replayed callback), :missing_client_id (the provider's
    # credentials are not configured in this environment), :access_denied
    # (the user said no at the provider). The message can carry text from
    # the callback's query string or the provider's response, so it is
    # logged escaped and truncated.
    def failure
      logger.warn("OAuth sign-in failed: #{omniauth_failure} ip=#{request.remote_ip}")
      redirect_to root_path
    end

    protected

    def omniauth_failure
      env = request.env
      error = env['omniauth.error']
      "provider=#{env['omniauth.error.strategy']&.name} " \
        "type=#{env['omniauth.error.type']} " \
        "error=#{error&.class}: #{error&.message.to_s.truncate(200).inspect}"
    end

    # One account per email address. When the provider reports an email that
    # already belongs to an account signing in another way, Devise's
    # uniqueness validation (and the unique index on users.email) rejects the
    # new record; say so instead of signing in a record that was never saved.
    def sign_in_from_omniauth(kind)
      user = User.from_omniauth(auth_hash)

      if user.persisted?
        flash[:notice] = t('devise.omniauth_callbacks.success', kind: kind)
        sign_in_and_redirect user, event: :authentication
      elsif (existing = User.find_for_authentication(email: auth_hash.info.email))
        redirect_with_email_taken(kind, existing)
      else
        redirect_with_errors(user)
      end
    end

    def log_oauth_rejection(reason)
      logger.warn(
        "OAuth sign-in rejected: provider=#{auth_hash.provider} " \
        "reason=#{reason} ip=#{request.remote_ip}"
      )
    end

    # Attribute names only in the log: the messages can quote the email.
    def redirect_with_errors(user)
      log_oauth_rejection(user.errors.attribute_names.join(','))
      redirect_to new_user_registration_url,
                  alert: user.errors.full_messages.join("\n")
    end

    def redirect_with_email_taken(kind, existing)
      log_oauth_rejection("email belongs to user=#{existing.id}")
      redirect_to new_user_session_path,
                  alert: t('devise.omniauth_callbacks.email_taken',
                           kind: kind,
                           email: existing.email,
                           existing_kind: existing.sign_in_method_name)
    end

    def auth_hash
      request.env['omniauth.auth']
    end
  end
end
