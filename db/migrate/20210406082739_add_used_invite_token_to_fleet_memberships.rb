class AddUsedInviteTokenToFleetMemberships < ActiveRecord::Migration[6.1]
  def change
    add_column :fleet_memberships, :used_invite_token, :string
  end
end
