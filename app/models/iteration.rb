class Iteration < ApplicationRecord
  belongs_to :automation_scenario
end

# == Schema Information
#
# Table name: iterations
#
#  id                     :integer          not null, primary key
#  iteration_time         :datetime
#  iteration_cost         :integer
#  automation_scenario_id :integer
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#