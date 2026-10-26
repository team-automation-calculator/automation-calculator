module Users
  class OmniauthCallbacksController < ::Devise::OmniauthCallbacksController
    def github
      sign_in_from_omniauth('GitHub')
    end

    def google_oauth2
      sign_in_from_omniauth('Google')
    end

    def failure
      redirect_to root_path
    end

    protected

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

    def redirect_with_errors(user)
      redirect_to new_user_registration_url,
                  alert: user.errors.full_messages.join("\n")
    end

    def redirect_with_email_taken(kind, existing)
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
