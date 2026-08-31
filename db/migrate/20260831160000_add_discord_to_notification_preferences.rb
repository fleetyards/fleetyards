# frozen_string_literal: true

# Discord DMs as a fourth delivery channel next to app, mail and push.
#
# Default false, and deliberately so: an unsolicited DM from a bot is the
# fastest way to get an application reported, and the existing channels already
# establish that a channel is something the reader turns on.
class AddDiscordToNotificationPreferences < ActiveRecord::Migration[8.1]
  def change
    add_column :notification_preferences, :discord, :boolean, default: false, null: false
  end
end
