class AddGroupToDocks < ActiveRecord::Migration[5.2]
  def change
    add_column :docks, :group, :string
  end
end
