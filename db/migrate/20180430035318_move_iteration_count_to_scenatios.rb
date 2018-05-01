class MoveIterationCountToScenatios < ActiveRecord::Migration[5.1]
  def change
    remove_column :solutions, :iteration_count, :integer
    add_column :automation_scenarios, :iteration_count, :integer, default: 10
  end
end
