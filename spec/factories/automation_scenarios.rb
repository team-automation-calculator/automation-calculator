FactoryBot.define do
  factory :automation_scenario do
    owner { create(:visitor) }
    iteration_count 10
    name { Faker::Lorem.sentence }
  end
end

# == Schema Information
#
# Table name: automation_scenarios
#
#  id              :bigint(8)        not null, primary key
#  owner_type      :string
#  owner_id        :bigint(8)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  iteration_count :integer          default(10)
#  name            :string
#
