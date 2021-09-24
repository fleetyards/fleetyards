class AddPublicFlagToHangarGroups < ActiveRecord::Migration[6.1]
  def change
    add_column :hangar_groups, :public, :boolean, default: false
  end
end
