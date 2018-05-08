class SolutionTuple
  attr_reader :solutions

  def initialize(solutions)
    @solutions = solutions
  end

  def list
    return if solutions.blank?
    unorderd_list =
      solutions.each_with_object({}) do |solution, set|
        set[solution] = cost(solution)
      end
    unorderd_list.sort_by { |_, v| v }.to_h.keys
  end

  private

  def cost(solution)
    solution.initial_cost + (solution.iteration_cost * solution.iteration_count)
  end
end
