class AutomationScenario < ApplicationRecord
  belongs_to :owner, polymorphic: true
  has_many :solutions, dependent: :destroy

  validates :iteration_count,
            numericality: { only_integer: true, greater_than: 0 }

  accepts_nested_attributes_for :solutions, reject_if: -> (attributes) {
    attributes[:initial_cost].blank? || attributes[:iteration_cost].blank?
  }
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
