class AddMatrixKeyToHardpoints < ActiveRecord::Migration[7.1]
  def change
    add_column :hardpoints, :matrix_key, :string
    add_column :hardpoints, :details, :string
    remove_column :hardpoints, :hardpoint_type, :integer
  end
end
