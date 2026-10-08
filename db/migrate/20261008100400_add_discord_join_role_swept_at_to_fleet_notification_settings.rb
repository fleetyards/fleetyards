# frozen_string_literal: true

class AddDiscordJoinRoleSweptAtToFleetNotificationSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :fleet_notification_settings, :discord_join_role_swept_at, :datetime
  end
end
