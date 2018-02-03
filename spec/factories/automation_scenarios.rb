FactoryBot.define do
  factory :automation_scenario do
    owner { create(:visitor) }
  end
end

# == Schema Information
#
# Table name: automation_scenarios
#
#  id         :integer          not null, primary key
#  owner_type :string
#  owner_id   :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
