module Api
  module V1
    class ApplicationController < Api::ApplicationController
      protected

      attr_reader :current_user, :current_visitor

      def authenticate!
        token = request.headers['HTTP_ACCESS_TOKEN']
        payload = JwtTokenService.decode_token(token)

        if payload[:user_id].present?
          @current_visitor = nil
          @current_user = User.find(payload[:user_id])
        elsif payload[:visitor_id].present?
          @current_visitor = Visitor.find(payload[:visitor_id])
          @current_user = nil
        else
          # neither user nor visitor found
          raise ActiveRecord::RecordNotFound
        end

      rescue JwtTokenService::ExpiredError
        head :unauthorized
      rescue JwtTokenService::DecodeError
        head :unauthorized
      rescue ActiveRecord::RecordNotFound
        head :unauthorized
      end

      def current_member
        current_user || current_visitor
      end
    end
  end
end
