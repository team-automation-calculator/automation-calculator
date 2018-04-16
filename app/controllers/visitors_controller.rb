class VisitorsController < ApplicationController
  def create
    @visitor = Visitor.create_with_random_uuid(request.remote_ip)
    @automation_scenario = AutomationScenario.create(owner_type: 'Visitor', owner_id: @visitor.id)
    redirect_to("/automation_scenarios/#{@automation_scenario.id}")
  end

  def index
    redirect_to(action: :create)
  end

  def update
    # fill in read
  end

  def destroy
    @visitor = Visitor.find(params[:id])
    @visitor.destroy
  end

  def show
    @visitor = Visitor.find(params[:id])
  end
end
