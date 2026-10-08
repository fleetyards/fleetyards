# frozen_string_literal: true

# A Discord user we have seen subscribed to a Discord scheduled event.
#
# A snapshot of Discord's state, not of ours: rows are written whatever the
# Fleetyards side made of the RSVP, because their only job is to let the next
# poll tell "this user unsubscribed" apart from "this user was never subscribed
# and answered on the website instead".
class DiscordEventSubscription < ApplicationRecord
  validates :discord_event_id, presence: true
  validates :discord_user_id, presence: true, uniqueness: {scope: :discord_event_id}

  scope :for_event, ->(discord_event_id) { where(discord_event_id: discord_event_id) }

  def self.user_ids_for(discord_event_id)
    for_event(discord_event_id).pluck(:discord_user_id)
  end
end
