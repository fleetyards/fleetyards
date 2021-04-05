class RemoveFleetInviteUrlIdFromFleetMemberships < ActiveRecord::Migration[6.1]
  def change
    remove_column :fleet_memberships, :fleet_invite_url_id, :uuid
  end
end
