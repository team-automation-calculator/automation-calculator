class Solution < ApplicationRecord
  belongs_to :automation_scenario

  validates :initial_cost,
            numericality: { only_integer: true, greater_than: 0 }
  validates :iteration_cost,
            numericality: { only_integer: true, greater_than: 0 }

  delegate :iteration_count, to: :automation_scenario

  def cost
    initial_cost + (iteration_cost * iteration_count)
  end

  def display_name
    name.presence || "Solution ##{id}"
  end

  def intersection(another_solution)
    iteration_cost_diff = another_solution.iteration_cost - iteration_cost
    return if iteration_cost_diff.zero?

    iteration =
      (initial_cost - another_solution.initial_cost).to_f / iteration_cost_diff
    cost = initial_cost + iteration * iteration_cost

    [iteration, cost]
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
