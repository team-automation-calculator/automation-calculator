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

      def decode_token
        token = request.headers['HTTP_ACCESS_TOKEN']
        JwtTokenService.decode_token(token)[:data]
      rescue JwtTokenService::ExpiredError
        head :unauthorized
      rescue JwtTokenService::DecodeError
        head :unauthorized
      rescue ActiveRecord::RecordNotFound
        head :unauthorized
      end
    end
  end
end
