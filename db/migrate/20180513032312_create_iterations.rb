class CreateIterations < ActiveRecord::Migration[5.1]
  def change
    create_table :iterations do |t|
      t.datetime :time
      t.integer :cost, limit: 8
      t.references :automation_scenario, foreign_key: true

      t.timestamps
    end
  end
end
