class AddIndexForFleetInvites < ActiveRecord::Migration[6.1]
  def change
    add_index :fleet_invite_urls, [:token, :fleet_id], unique: true
  end
end
