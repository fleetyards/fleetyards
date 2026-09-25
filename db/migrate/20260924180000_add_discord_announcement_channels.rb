# frozen_string_literal: true

class AddDiscordAnnouncementChannels < ActiveRecord::Migration[8.1]
  def change
    add_column :fleet_squadrons, :discord_channel_id, :string
    add_column :fleet_notification_settings, :discord_announcement_channel_id, :string
  end
end
