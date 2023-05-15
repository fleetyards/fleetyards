class RemoveUnneededIndexes < ActiveRecord::Migration[7.0]
  def change
    remove_index :hangar_groups, name: "index_hangar_groups_on_user_id", column: :user_id
    remove_index :vehicles, name: "index_vehicles_on_model_id", column: :model_id
  end
end
