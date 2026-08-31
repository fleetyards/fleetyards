# frozen_string_literal: true

# /fleet resolves the fleet from the guild the command came from, which is the
# first read that looks a fleet up by this column on a request path. The column
# has existed unindexed since the Discord binding was added.
#
# Not unique: nothing stops two fleets from being pointed at the same guild
# today, and turning that into a constraint is a separate decision from making
# the lookup fast.
class AddIndexToFleetNotificationSettingsDiscordGuildId < ActiveRecord::Migration[8.1]
  def change
    add_index :fleet_notification_settings, :discord_guild_id
  end
end
