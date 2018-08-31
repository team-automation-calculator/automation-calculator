class AutomationScenarioForGraphSerializer < ActiveModel::Serializer
  attributes :iteration_count, :display_name, :intersections
  has_many :solutions do
    object.solutions.reject(&:new_record?)
  end

  def intersections
    object
      .solutions_combinations
      .map(&:intersection_point_within_boundaries)
      .compact
  end
end
