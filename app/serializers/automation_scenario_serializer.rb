class AutomationScenarioSerializer < ActiveModel::Serializer
  attributes :id, :iteration_count, :display_name

  has_many :solutions do
    object.solutions.reject(&:new_record?)
  end
end
