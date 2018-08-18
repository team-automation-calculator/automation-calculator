class SolutionPair
  attr_reader :solution1, :solution2

  class UnpairedSolutionsError < StandardError; end

  def initialize(solution1, solution2)
    @solution1 = solution1
    @solution2 = solution2

    # we cancompare solutions from the same scenario only
    if solution1.automation_scenario_id != solution2.automation_scenario_id
      raise UnpairedSolutionsError
    end
  end

  def intersection_point
    iteration_cost_diff = solution2.iteration_cost - solution1.iteration_cost
    return if iteration_cost_diff.zero?

    iteration =
      (solution1.initial_cost - solution2.initial_cost).to_f / iteration_cost_diff

    [iteration, solution1.cost_at(iteration)]
  end

  def intersection_within_boundaries?
    iteration = intersection_point&.first
    return false if iteration.nil?

    iteration.negative? || iteration > solution1.count
  end

  def intersection_point_within_boundaries
    return unless intersection_within_boundaries?

    intersection_coordinates
  end

  def difference
    solution1.cost - solution2.cost
  end

  def difference_formatted
    '%.2f' % difference
  end

  def intersection_formatted
    point = intersection_point_within_boundaries

    return 'No intersection' if point.blank?

    '[%.2f, %.2f]' % point
  end
end
