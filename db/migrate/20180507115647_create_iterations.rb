class CreateIterations < ActiveRecord::Migration[5.1]
  def change
    create_table :iterations do |t|
      t.datetime :iteration_time
      t.integer :iteration_cost, limit: 8
      t.references :automation_scenario, foreign_key: true

      t.timestamps
    end
  end
end
