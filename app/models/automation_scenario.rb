class AutomationScenario < ApplicationRecord
  belongs_to :owner, polymorphic: true
end
