class RemoveFirstVisitTimeFromVisitor < ActiveRecord::Migration[5.1]
  def change
    remove_column :visitors, :first_visit_time, :datetime
  end
end
