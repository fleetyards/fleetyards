# frozen_string_literal: true

class DropEnabledDiscordEventsFromFleetNotificationSettings < ActiveRecord::Migration[8.0]
  def change
    remove_column :fleet_notification_settings, :enabled_discord_events, :text, default: []
  end
end
