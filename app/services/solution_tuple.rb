class SolutionTuple
  attr_reader :solutions

  def initialize(solutions)
    @solutions = solutions
  end

  def list
    return if solutions.blank?
    solutions.sort_by(&:cost)
  end
end
