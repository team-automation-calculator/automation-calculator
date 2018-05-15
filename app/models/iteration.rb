class Iteration < ApplicationRecord
  belongs_to :automation_scenario

  validates :cost, numericality: { only_integer: true, greater_than: 0 }
end

# == Schema Information
#
# Table name: iterations
#
#  id                     :integer          not null, primary key
#  time                   :datetime
#  cost                   :integer
#  automation_scenario_id :integer
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
