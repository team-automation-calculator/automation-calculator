class AutomationScenario < ApplicationRecord
  belongs_to :owner, polymorphic: true
  has_many :solutions, dependent: :destroy
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
