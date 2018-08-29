module API
  module V1
    class SolutionsController < API::V1::ApplicationController
      before_action :authenticate!
      before_action :find_scenario, only: %i[index create]
      before_action :find_solution, only: %i[show update destroy]

      def index
        render json: @automation_scenario.solutions
      end

      def create
        solution =
          @automation_scenario.solutions.create! permitted_params

        render json: solution
      end

      def show
        render json: @solution
      end

      def update
        @solution.update! permitted_params

        render json: @solution
      end

      def destroy
        @solution.destroy!

        head :ok
      end

      protected

      def find_automation_scenario
        @automation_scenario =
          current_member.automation_scenarios.find(
            params[:automation_scenario_id]
          )
      end

      def find_solution
        @solution = Solution.find params[:id]

        # a primitive permissions check
        raise ActiveRecord::NotFound unless
          @solution.automation_scenario.owner == current_member
      end

      def permitted_params
        params.permit(:name, :initial_cost, :iteration_cost)
      end
    end
  end
end
