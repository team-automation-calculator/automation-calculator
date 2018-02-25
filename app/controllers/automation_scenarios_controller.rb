class AutomationScenariosController < ApplicationController
  def create
    @automation_scenario = AutomationScenario.create!(creation_params)
    redirect_to(action: :show, id: @automation_scenario.id)
  end

  def show
    @automation_scenario = AutomationScenario.find(automation_scenario_params)
  end

  def update
    @automation_scenario = AutomationScenario.find(automation_scenario_params)
  end

  def destroy
    @automation_scenario = AutomationScenario.find(automation_scenario_params)
    @automation_scenario.destroy
  end

  private

  def creation_params
    params.require(:automation_scenario_create_params).permit(:owner_type, :owner_id)
  end

  def automation_scenario_params
    params.require(:id)
  end
end
