class AddSerialToVehicles < ActiveRecord::Migration[6.1]
  def change
    add_column :vehicles, :serial, :string
    add_index :vehicles, :serial, unique: true
  end
end
