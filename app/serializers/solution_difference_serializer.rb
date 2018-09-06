class SolutionDifferenceSerializer < ActiveModel::Serializer
  attributes :solution1_id, :solution2_id, :difference

  def solution1_id
    object.solution1.id
  end

  def solution2_id
    object.solution2.id
  end
end
