module API
  class IterationsController < ApplicationController
    before_action :set_iteration, only: %i[show update destroy]

    def index
      # TODO: list other endpoint addresses here in proper REST format
      render json: { methods: %i[show create update destroy] }
    end

    def show
      render json: @iteration
    end

    def create
      @iteration = Iteration.new(create_iteration_params)
      if @iteration.save
        render json: @iteration, status: :created
      else
        render json: @iteration.errors, status: :unprocessable_entity
      end
    end

    def update
      @iteration.update(iteration_params)
      response.status = if @iteration.valid?
                          200
                        else
                          :unprocessable_entity
                        end
    end

    def destroy
      @iteration.destroy
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_iteration
      @iteration = Iteration.find(params[:id])
    end

    # Never trust parameters from the scary internet,
    # only allow the white list through.
    def iteration_params
      params.require(:iteration).permit(
        :time, :cost
      )
    end

    def create_iteration_params
      params.require(:iteration).permit(
        :time, :cost, :automation_scenario_id
      )
    end
  end
end
