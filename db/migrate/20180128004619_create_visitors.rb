class CreateVisitors < ActiveRecord::Migration[5.1]
  def change
    create_table :visitors do |t|
      t.datetime :first_visit_time
      t.string :ip
      t.string :uuid

      t.timestamps
    end
    add_index :visitors, :uuid, unique: true
  end
end
