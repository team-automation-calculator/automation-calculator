class SolutionsController < ApplicationController
  before_action :set_solution, only: %i[show update destroy]

  def show; end

  def create
    @solution = Solution.new(solution_params)

    if @solution.save
      redirect_to @solution, notice: 'Solution was successfully created.'
    else
      head :unprocessable_entity
    end
  end

  def update
    if @solution.update(solution_params)
      redirect_to @solution, notice: 'Solution was successfully updated.'
    else
      head :unprocessable_entity
    end
  end

  def destroy
    @solution.destroy!
    head :ok
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_solution
    @solution = Solution.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def solution_params
    params.require(:solution).permit(
      :initial_cost, :iteration_cost, :iteration_count, :automation_scenario_id
    )
  end
end
