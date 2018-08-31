module API
  module V1
    class AutomationScenariosController < API::V1::ApplicationController
      before_action :authenticate!
      before_action :find_automation_scenario, only: %i[show update destroy]

      def index
        render json: current_member.automation_scenarios
      end

      def create
        automation_scenario =
          current_member.automation_scenarios.create! permitted_params

        render json: automation_scenario
      end

      def show
        render json: @automation_scenario
      end

      def update
        @automation_scenario.update! permitted_params

        render json: @automation_scenario
      end

      def destroy
        @automation_scenario.destroy!
        head :ok
      end

      protected

      def find_automation_scenario
        @automation_scenario =
          current_member.automation_scenarios.find params[:id]
      end

      def permitted_params
        params.permit(:name, :iteration_count)
      end
    end
  end
end
