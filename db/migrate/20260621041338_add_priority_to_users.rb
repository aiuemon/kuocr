class AddPriorityToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :priority, :integer, null: false, default: 3
    add_column :users, :priority_manually_set, :boolean, null: false, default: false
    add_check_constraint :users, "priority BETWEEN 1 AND 5", name: "chk_users_priority_range"
  end
end
