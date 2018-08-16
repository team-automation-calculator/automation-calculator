class Solution < ApplicationRecord
  belongs_to :automation_scenario

  validates :initial_cost,
            numericality: { only_integer: true, greater_than: 0 }
  validates :iteration_cost,
            numericality: { only_integer: true, greater_than: 0 }

  delegate :iteration_count, to: :automation_scenario

  def cost
    cost_at iteration_count
  end

  def cost_at(iteration)
    initial_cost + (iteration_cost * iteration)
  end

  def display_name
    name.presence || "Solution ##{id}"
  end

  def intersection(another_solution, check_boundaries: false)
    iteration_cost_diff = another_solution.iteration_cost - iteration_cost
    return if iteration_cost_diff.zero?

    iteration =
      (initial_cost - another_solution.initial_cost).to_f / iteration_cost_diff
    return if check_boundaries &&
              (iteration.negative? || iteration > iteration_count)

    [iteration, cost_at(iteration)]
  end
end

# == Schema Information
#
# Table name: solutions
#
#  id                     :bigint(8)        not null, primary key
#  initial_cost           :integer
#  iteration_cost         :integer
#  automation_scenario_id :bigint(8)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  name                   :string
#
