class AddUsageCountToFleetInviteUrls < ActiveRecord::Migration[7.2]
  def change
    add_column :fleet_invite_urls, :usage_count, :integer, default: 0, null: false
  end
end
