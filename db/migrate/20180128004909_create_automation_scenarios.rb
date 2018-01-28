class CreateAutomationScenarios < ActiveRecord::Migration[5.1]
  def change
    create_table :automation_scenarios do |t|
      t.references :owner, polymorphic: true

      t.timestamps
    end
  end
end
