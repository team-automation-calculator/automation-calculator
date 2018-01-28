FactoryBot.define do
  factory :automation_scenario do
    owner { create(:visitor) }
  end
end
