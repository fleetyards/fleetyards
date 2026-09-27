# frozen_string_literal: true

# Before these columns were validated a fleet could save its server's name as
# the guild id. Nothing sent to Discord with it ever worked, and the row would
# now fail validation on the next unrelated save of the settings page.
class ClearInvalidDiscordIdsFromNotificationSettings < ActiveRecord::Migration[8.1]
  COLUMNS = %w[
    discord_guild_id
    discord_channel_id
    discord_member_role_id
    discord_announcement_channel_id
    discord_officers_channel_id
  ].freeze

  def up
    COLUMNS.each do |column|
      # An id pasted with whitespace around it is one the model now strips and
      # accepts, so it is kept rather than cleared.
      FleetNotificationSetting
        .where("#{column} ~ '^\\s|\\s$'")
        .update_all(["#{column} = regexp_replace(#{column}, '^\\s+|\\s+$', '', 'g'), updated_at = ?", Time.current])

      FleetNotificationSetting
        .where.not(column => nil)
        .where.not("#{column} ~ '^[0-9]{15,25}$'")
        .update_all(column => nil, :updated_at => Time.current)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
