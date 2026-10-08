# frozen_string_literal: true

class AddDiscordRoleGrantedToFleetMemberships < ActiveRecord::Migration[8.1]
  def change
    add_column :fleet_memberships, :discord_role_granted, :boolean, null: false, default: false
  end
end
