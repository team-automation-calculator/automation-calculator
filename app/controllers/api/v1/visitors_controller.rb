module Api
  module V1
    class VisitorsController < Api::V1::ApplicationController
      def create
        # create and sign in a visitor
        visitor = Visitor.create_with_random_uuid(request.remote_ip)
        automation_scenario = visitor.automation_scenarios.create!

        token = JwtTokenService.encode_token(visitor_id: visitor.id)
        response.set_header('Access-Token', token)
        render json: visitor
      end
    end
  end
end
