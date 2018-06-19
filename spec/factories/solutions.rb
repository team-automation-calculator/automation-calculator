FactoryBot.define do
  factory :solution do
    initial_cost 1
    iteration_cost 1
    name { Faker::Lorem.sentence }

    automation_scenario
  end
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
