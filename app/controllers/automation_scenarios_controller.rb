class AutomationScenariosController < ApplicationController
  before_action :set_scenario, only: %i[show update destroy]

  def create
    @automation_scenario = AutomationScenario.create!(creation_params)
    redirect_to(action: :show, id: @automation_scenario.id)
  end

  def show
    # show a new solution in the solutions list
    @automation_scenario.solutions.build
  end

  def update
    @automation_scenario.update update_params
    # regardless of the result we redirect to the same page
    redirect_to @automation_scenario
  end

  def destroy
    @automation_scenario.destroy
  end

  private

  def creation_params
    params.require(:automation_scenario)
          .permit(:owner_type, :owner_id, :iteration_count, :name)
  end

  def update_params
    params.require(:automation_scenario).permit(
      :iteration_count, :name,
      solutions_attributes: %i[id initial_cost iteration_cost name]
    )
  end

  def set_scenario
    @automation_scenario = AutomationScenario.find params[:id]
  end
end
