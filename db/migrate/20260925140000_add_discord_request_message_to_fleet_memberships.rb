# frozen_string_literal: true

class AddDiscordRequestMessageToFleetMemberships < ActiveRecord::Migration[8.1]
  def change
    add_column :fleet_memberships, :discord_request_channel_id, :string
    add_column :fleet_memberships, :discord_request_message_id, :string
  end
end
