class SolutionIntersectionSerializer < ActiveModel::Serializer
  attributes :solution1_id, :solution2_id, :intersection

  def solution1_id
    object.solution1.id
  end

  def solution2_id
    object.solution2.id
  end

  def intersection
    object.intersection_point_within_boundaries
  end
end
