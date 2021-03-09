class ChangeUniqueIndexOnVehicles < ActiveRecord::Migration[6.1]
  def change
    remove_index :vehicles, :serial, unique: true
    add_index :vehicles, [:serial, :user_id], unique: true
  end
end
