class AutomationScenarioSerializer < ActiveModel::Serializer
  attributes :iteration_count, :display_name, :intersections
  has_many :solutions do
    object.solutions.reject(&:new_record?)
  end

  def intersections
    object.intersections_and_differences.map(&:third).compact
  end
end
