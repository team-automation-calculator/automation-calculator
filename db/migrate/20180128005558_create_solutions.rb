class CreateSolutions < ActiveRecord::Migration[5.1]
  def change
    create_table :solutions do |t|
      t.integer :initial_cost
      t.integer :iteration_cost
      t.integer :iteration_count
      t.references :automation_scenario, foreign_key: true

      t.timestamps
    end
  end
end
