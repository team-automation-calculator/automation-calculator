class Iteration < ApplicationRecord
  belongs_to :automation_scenario

  validates :cost, numericality: { only_integer: true, greater_than: 0 }
end

# == Schema Information
#
# Table name: iterations
#
#  id                     :bigint(8)        not null, primary key
#  time                   :datetime
#  cost                   :bigint(8)
#  automation_scenario_id :bigint(8)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
