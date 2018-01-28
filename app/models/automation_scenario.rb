class AutomationScenario < ApplicationRecord
  belongs_to :owner, polymorphic: true
  has_many :solutions, dependent: :destroy
end
