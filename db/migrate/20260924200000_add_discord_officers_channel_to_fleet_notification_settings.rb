# frozen_string_literal: true

class AddDiscordOfficersChannelToFleetNotificationSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :fleet_notification_settings, :discord_officers_channel_id, :string
  end
end
