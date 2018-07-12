class AutomationScenario < ApplicationRecord
  belongs_to :owner, polymorphic: true
  has_many :solutions, dependent: :destroy
  has_many :iterations, dependent: :destroy

  validates :iteration_count,
            numericality: { only_integer: true, greater_than: 0 }

  accepts_nested_attributes_for :solutions, reject_if: lambda { |attributes|
    attributes[:initial_cost].blank? || attributes[:iteration_cost].blank?
  }

  def display_name
    name.presence || "Automation Scenario ##{id}"
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
