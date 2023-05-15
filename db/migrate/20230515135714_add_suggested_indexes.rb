class AddSuggestedIndexes < ActiveRecord::Migration[7.0]
  def change
    commit_db_transaction
    add_index :fleet_vehicles, [:vehicle_id], algorithm: :concurrently
    add_index :users, [:normalized_username], algorithm: :concurrently
  end
end
