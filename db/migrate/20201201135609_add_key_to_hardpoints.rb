class AddKeyToHardpoints < ActiveRecord::Migration[6.0]
  def change
    add_column :hardpoints, :key, :string
  end
end
