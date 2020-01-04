class AddFieldsToHardpoints < ActiveRecord::Migration[5.2]
  def change
    add_column :hardpoints, :rsi_key, :string
    add_column :hardpoints, :deleted_at, :datetime
  end
end
