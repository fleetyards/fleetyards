class AddPublicHangarStatsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :public_hangar_stats, :boolean, default: false
  end
end
