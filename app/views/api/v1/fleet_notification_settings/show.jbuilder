# frozen_string_literal: true

json.id @setting.id
json.fleet_id @setting.fleet_id
json.enabled_in_app_events Array(@setting.enabled_in_app_events)
json.enabled_discord_events Array(@setting.enabled_discord_events)
json.discord_guild_id @setting.discord_guild_id
json.discord_channel_id @setting.discord_channel_id
json.discord_webhook_configured @setting.discord_webhook_url.present?
