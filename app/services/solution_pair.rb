class SolutionPair
  attr_reader :solution1, :solution2

  class UnpairedSolutionsError < StandardError; end

  def initialize(solution1, solution2)
    @solution1 = solution1
    @solution2 = solution2

    # we can compare solutions from the same scenario only
    raise UnpairedSolutionsError if
      solution1.automation_scenario_id != solution2.automation_scenario_id
  end

  def intersection_point
    iteration = intersection_iteration
    return if iteration.nil?

    [iteration, solution1.cost_at(iteration)]
  end

  def intersection_within_boundaries?
    iteration = intersection_iteration

    iteration.present? &&
      iteration.positive? &&
      iteration <= solution1.iteration_count
  end

  def intersection_point_within_boundaries
    return unless intersection_within_boundaries?

    intersection_point
  end

  def difference
    solution1.cost - solution2.cost
  end

  def difference_formatted
    format '%.2f', difference
  end

  def intersection_formatted
    point = intersection_point_within_boundaries

    return 'No intersection' if point.blank?

    format '[%.2f, %.2f]', point.first, point.second
  end

  protected

  def intersection_iteration
    cost_diff = solution2.iteration_cost - solution1.iteration_cost
    return if cost_diff.zero?

    (solution1.initial_cost - solution2.initial_cost).to_f / cost_diff
  end
end
