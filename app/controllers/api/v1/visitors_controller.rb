module API
  module V1
    class VisitorsController < API::V1::ApplicationController
      rate_limit to: 30, within: 1.minute

      def create
        # create and sign in a visitor
        visitor = Visitor.create_with_random_uuid(request.remote_ip)
        visitor.automation_scenarios.create!

        token = JwtTokenService.encode_token(visitor_id: visitor.id)
        response.set_header('Access-Token', token)
        render json: visitor, status: :created
      end
    end
  end
end
