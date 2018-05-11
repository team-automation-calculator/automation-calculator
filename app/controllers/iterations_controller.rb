class IterationsController < ApplicationController
  before_action :set_automation_scenario
  before_action :set_iteration, only: %i[show edit update destroy]

  def index
    @iterations = @automation_scenario.iterations
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @iterations }
    end
  end

  def show 
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @iteration }
    end
  end

  def new
    @iteration = @automation_scenario.iterations.new
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @iteration }
    end
  end

  def create
    @iteration = @automation_scenario.iterations.new(create_iteration_params)

    respond_to do |format|
      if @iteration.save
        format.html { redirect_to automation_scenario_iterations_url(automation_scenario_id: params[:automation_scenario_id]), notice: 'Iteration was successfully created.' }
        format.json { render json: @iteration, status: :created }
      else
        format.html { render action: "new" }
        format.json { render json: @iteration.errors, status: :unprocessable_entity }
       end
    end
  end

  def edit
    respond_to do |format|
      format.html # edit.html.erb
      format.json { render json: @iteration }
    end  
  end

  def update
    respond_to do |format|
      if @iteration.update(iteration_params)
        format.html { redirect_to automation_scenario_iterations_url(automation_scenario_id: params[:automation_scenario_id]), notice: 'Iteration was successfully Updated.' }
        format.json { render json: @iteration, status: :updated }
      else
        format.html { render action: "edit" }
        format.json { render json: @iteration.errors, status: :unprocessable_entity }
       end
    end
  end

  def destroy
    respond_to do |format|
      if @iteration.destroy!
        format.html { redirect_to automation_scenario_iterations_url(automation_scenario_id: params[:automation_scenario_id]), notice: 'Iteration was successfully deleted.' }
        format.json { render json: @iteration, status: :deleted }
      else
        format.html { render action: "index" }
        format.json { render json: @iteration.errors, status: :unprocessable_entity }
       end
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_iteration
    @iteration = @automation_scenario.iterations.find(params[:id])
  end
  def set_automation_scenario
    @automation_scenario = AutomationScenario.find(params[:automation_scenario_id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def iteration_params
    params.require(:iteration).permit(
      :iteration_time, :iteration_cost
    )
  end

  def create_iteration_params
    params.require(:iteration).permit(
      :iteration_time, :iteration_cost, :automation_scenario_id
    )
  end
end
