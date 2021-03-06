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
