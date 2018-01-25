class AddSortToHangarGroups < ActiveRecord::Migration[5.1]
  def change
    add_column :hangar_groups, :sort, :integer
  end
end
