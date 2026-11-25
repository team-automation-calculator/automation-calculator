module API
  module V1
    class ApplicationController < API::ApplicationController
      protected

      attr_reader :current_user, :current_visitor

      # some actions are allowed for users only
      def authenticate_user!
        payload = decode_token
        return unless payload.is_a? Hash

        @current_user = User.find payload[:user_id]
      end

      def authenticate!
        payload = decode_token
        return unless payload.is_a? Hash

        find_member payload[:user_id], payload[:visitor_id]
      end

      def find_member(user_id, visitor_id)
        if user_id.present?
          @current_visitor = nil
          @current_user = User.find(user_id)
        elsif visitor_id.present?
          @current_visitor = Visitor.find(visitor_id)
          @current_user = nil
        else
          # neither user nor visitor found
          raise ActiveRecord::RecordNotFound
        end
      end

      def current_member
        current_user || current_visitor
      end

      # Re-authenticate the bearer-token holder before a sensitive change
      # (password or email). A valid JWT alone is not enough.
      def verify_current_password!
        return if valid_current_password?

        render json: { error: 'Invalid current password' },
               status: :unauthorized
      end

      def valid_current_password?
        password = params[:current_password]
        password.present? && current_user&.valid_password?(password)
      end

      def decode_token
        token = request.headers['HTTP_ACCESS_TOKEN']
        JwtTokenService.decode_token(token)[:data]
      rescue JwtTokenService::ExpiredError => e
        render_unauthorized(:info, e)
      rescue JwtTokenService::DecodeError, ActiveRecord::RecordNotFound => e
        render_unauthorized(:warn, e)
      end

      # Every rejected token gets the same response body; the reason goes to
      # the log only. The token itself is never logged.
      def render_unauthorized(level, error)
        logger.public_send(
          level,
          "API 401: access token rejected: #{error.class}: #{error.message}"
        )
        render json: { error: 'Unauthorized' }, status: :unauthorized
      end
    end
  end
end
