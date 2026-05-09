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
#  id                     :bigint(8)        not null, primary key
#  time                   :datetime
#  cost                   :bigint(8)
#  automation_scenario_id :bigint(8)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
