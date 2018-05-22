class IterationSerializer < ActiveModel::Serializer
  attributes :id, :time, :cost, :automation_scenario_id
end
