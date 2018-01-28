class Solution < ApplicationRecord
  belongs_to :automation_scenario

  validates :initial_cost, numericality: { only_integer: true, greater_than: 0 }
  validates :iteration_cost, numericality: { only_integer: true, greater_than: 0 }
  validates :iteration_count, numericality: { only_integer: true, greater_than: 0 }
end
