class AddUniqueIndexToHangarGroups < ActiveRecord::Migration[7.0]
  def change
    add_index :hangar_groups, [:user_id, :name], unique: true
  end
end
