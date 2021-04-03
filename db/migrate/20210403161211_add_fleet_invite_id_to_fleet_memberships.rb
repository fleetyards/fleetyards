class AddFleetInviteIdToFleetMemberships < ActiveRecord::Migration[6.1]
  def change
    add_column :fleet_memberships, :fleet_invite_url_id, :uuid
    add_column :fleet_memberships, :invited_by, :uuid
  end
end
