# frozen_string_literal: true

# One row per Discord user we have seen subscribed to a Discord scheduled event.
#
# This exists to make the *withdrawal* direction safe. RSVPs arrive by polling
# Discord's subscriber list, and a Fleetyards-native event-level "interested"
# signup is byte-for-byte indistinguishable from one a Discord click produced --
# `ScheduledEventRsvpHandler#withdrawable?` can only ask "interested and no
# slot?". Diffing the subscriber list against Fleetyards signups would
# therefore withdraw the signup of every member who answered on the website and
# never touched Discord.
#
# So the poll diffs against this snapshot of Discord's own state instead: a
# withdrawal only ever happens for a user who was previously seen subscribed
# and has since unsubscribed.
#
# Keyed by discord_event_id rather than by FleetEvent: a recurring series
# pushes one Discord event per occurrence, and those ids live on
# fleet_event_occurrence_states, so the id is the only thing both cases share.
class CreateDiscordEventSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :discord_event_subscriptions, id: :uuid do |t|
      t.string :discord_event_id, null: false
      t.string :discord_user_id, null: false

      t.timestamps
    end

    # The poll reads the whole snapshot for one event, then inserts and deletes
    # by the pair.
    add_index :discord_event_subscriptions,
      %i[discord_event_id discord_user_id],
      unique: true,
      name: "index_discord_event_subscriptions_on_event_and_user"
  end
end
