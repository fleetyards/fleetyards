class AddGroupToHardpoints < ActiveRecord::Migration[7.1]
  def change
    add_column :hardpoints, :group, :integer
  end
end
