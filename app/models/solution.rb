class Solution < ApplicationRecord
  belongs_to :automation_scenario

  validates :initial_cost, numericality: { only_integer: true, greater_than: 0 }
  validates :iteration_cost, numericality: { only_integer: true, greater_than: 0 }

  delegate :iteration_count, to: :automation_scenario
end

# == Schema Information
#
# Table name: solutions
#
#  id                     :integer          not null, primary key
#  initial_cost           :integer
#  iteration_cost         :integer
#  automation_scenario_id :integer
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
