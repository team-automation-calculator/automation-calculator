FactoryBot.define do
  factory :iteration do
    time { Time.zone.now.yesterday }
    cost 1

    automation_scenario
  end
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
