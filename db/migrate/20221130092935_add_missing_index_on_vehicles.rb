class AddMissingIndexOnVehicles < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    add_index :vehicles, [:model_id, :id], algorithm: :concurrently
  end
end
