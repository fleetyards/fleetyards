class AddGroupKeyToHardpoints < ActiveRecord::Migration[7.1]
  def change
    add_column :hardpoints, :group_key, :string
  end
end
