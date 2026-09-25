# frozen_string_literal: true

class AddDiscordDigestTimezoneToFleetNotificationSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :fleet_notification_settings, :discord_digest_timezone, :string
  end
end
