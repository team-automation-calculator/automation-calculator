class AutomationScenario < ApplicationRecord
  belongs_to :owner, polymorphic: true
  has_many :solutions, dependent: :destroy

  validates :iteration_count,
            numericality: { only_integer: true, greater_than: 0 }
end

# == Schema Information
#
# Table name: automation_scenarios
#
#  id              :integer          not null, primary key
#  owner_type      :string
#  owner_id        :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  iteration_count :integer          default(10)
#
