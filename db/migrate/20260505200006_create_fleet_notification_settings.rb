# frozen_string_literal: true

class CreateFleetNotificationSettings < ActiveRecord::Migration[7.2]
  def change
    create_table :fleet_notification_settings, id: :uuid do |t|
      t.references :fleet, type: :uuid, null: false, foreign_key: true, index: {unique: true}

      # Phase B: in-app notifications
      t.text :enabled_in_app_events,
        default: ["---", "- fleet_event.published", "- fleet_event.locked",
          "- fleet_event.starting_soon", "- fleet_event.cancelled",
          "- fleet_event_signup.created", "- fleet_event_signup.withdrawn"].join("\n")

      # Phase C: Discord — reserved
      t.text :discord_webhook_url
      t.string :discord_guild_id
      t.string :discord_channel_id
      t.text :enabled_discord_events, default: "--- []\n"

      t.timestamps
    end
  end
end
