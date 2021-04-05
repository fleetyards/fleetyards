class AddFieldsToFleetInviteUrls < ActiveRecord::Migration[6.1]
  def change
    add_column :fleet_invite_urls, :expires_after, :datetime
    add_column :fleet_invite_urls, :limit, :integer
  end
end
