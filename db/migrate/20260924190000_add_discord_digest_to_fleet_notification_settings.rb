# frozen_string_literal: true

class AddDiscordDigestToFleetNotificationSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :fleet_notification_settings, :discord_digest_weekday, :integer
    add_column :fleet_notification_settings, :discord_digest_time, :string
    add_column :fleet_notification_settings, :discord_digest_sent_at, :datetime
    add_index :fleet_notification_settings, :discord_digest_weekday, where: "discord_digest_weekday IS NOT NULL"
  end
end
