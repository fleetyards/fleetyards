class ChangeIndexForFleetInviteUrls < ActiveRecord::Migration[6.1]
  def change
    remove_index :fleet_invite_urls, [:token, :fleet_id], unique: true
    add_index :fleet_invite_urls, :token, unique: true
  end
end
