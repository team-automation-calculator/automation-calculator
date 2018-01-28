FactoryBot.define do
  factory :solution do
    initial_cost 1
    iteration_cost 1
    iteration_count 1
    automation_scenario { create(:automation_scenario) }
  end
end
