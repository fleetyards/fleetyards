class AddFieldsToHardpoints < ActiveRecord::Migration[7.1]
  def change
    add_column :hardpoints, :category, :integer
    add_column :hardpoints, :hardpoint_type, :integer
  end
end
