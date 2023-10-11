class AddCounterCacheForModelsToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :purchased_vehicles_count, :integer, default: 0, null: false
    add_column :users, :wanted_vehicles_count, :integer, default: 0, null: false
  end
end
