# frozen_string_literal: true

class AddDiscordJoinRoleToFleetNotificationSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :fleet_notification_settings, :discord_join_role_id, :string
  end
end
