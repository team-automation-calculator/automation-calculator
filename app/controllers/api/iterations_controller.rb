module API
  # Authenticated, owner-scoped CRUD for iterations. Inherits the JWT auth
  # helpers (authenticate!, current_member) from the V1 base controller and
  # scopes every lookup to the current member's scenarios, so a caller can
  # neither read nor mutate another member's data.
  class IterationsController < API::V1::ApplicationController
    before_action :authenticate!
    before_action :set_iteration, only: %i[show update destroy]

    def index
      render json: member_iterations
    end

    def show
      render json: @iteration
    end

    def create
      @iteration = scenario_for_create.iterations.new(iteration_params)
      if @iteration.save
        render json: @iteration, status: :created
      else
        render json: @iteration.errors, status: :unprocessable_content
      end
    end

    def update
      @iteration.update(iteration_params)
      response.status = if @iteration.valid?
                          200
                        else
                          :unprocessable_content
                        end
    end

    def destroy
      @iteration.destroy
    end

    private

    # Iterations reachable by the caller: only those on scenarios they own.
    def member_iterations
      Iteration.where(automation_scenario: current_member.automation_scenarios)
    end

    def set_iteration
      @iteration = member_iterations.find(params[:id])
    end

    # Only allow attaching an iteration to a scenario the member owns; a
    # missing or unowned id raises RecordNotFound (handled as 404).
    def scenario_for_create
      current_member.automation_scenarios.find(
        create_iteration_params[:automation_scenario_id]
      )
    end

    def iteration_params
      params.require(:iteration).permit(:time, :cost)
    end

    def create_iteration_params
      params.require(:iteration).permit(:time, :cost, :automation_scenario_id)
    end
  end
end
