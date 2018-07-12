class AddNamesToScenariosAndSolutions < ActiveRecord::Migration[5.2]
  def change
    add_column :automation_scenarios, :name, :string
    add_column :solutions, :name, :string
  end
end
