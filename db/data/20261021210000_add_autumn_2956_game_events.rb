# frozen_string_literal: true

# The game's own events from October to December 2956, so the homepage has the
# 'verse to show from the start.
#
# Day of the Vara and RSI Discovery Month carry the dates RSI announced -- none
# yet for the end of Discovery Month, so it has no end. IAE takes its dates from
# the free rental schedule the game files carry. Luminalia had none yet, so it
# goes in unpublished with the dates past years point to, for an admin to
# confirm and publish once RSI announces them.
#
# Every time is 17:00 UTC, about when an event goes live; RSI names the days,
# not the hour.
class AddAutumn2956GameEvents < ActiveRecord::Migration[8.1]
  OTHER = 0

  EVENTS = [
    {
      title: "RSI Discovery Month",
      description: "Transport, defense and collection contracts across Stanton earn points towards " \
        "permanent rewards, and one contract unlocks a five-day rental of the Constellation Mk V " \
        "Centaurus with its Skylark.",
      location: "Stanton",
      url: "https://robertsspaceindustries.com/en/comm-link/transmission/21334-Alpha-4102-RSI-Discovery-Month",
      starts_at: "2026-10-09 17:00:00",
      published: true
    },
    {
      title: "Day of the Vara 2956",
      description: "The 'verse remembers the Vara: the pumpkin contest returns, Kill Collector is back " \
        "in Arena Commander, and the holiday paints are on sale.",
      url: "https://robertsspaceindustries.com/community-hub/events",
      starts_at: "2026-10-21 17:00:00",
      ends_at: "2026-11-09 17:00:00",
      published: true
    },
    {
      title: "Intergalactic Aerospace Expo 2956",
      description: "Every manufacturer in New Babbage, each with two days of free rentals: RSI, " \
        "Origin, Anvil, Crusader and Tumbril, Drake, Argo, Consolidated Outland, Greycat and " \
        "Grey's Market, Kruger, Mirai and MISC, Aegis, then Aopoa, Banu, Esperia and Gatac. " \
        "Best in Show on 22 November, and from 23 November every IAE ship to try for free.",
      location: "New Babbage, microTech",
      url: "https://robertsspaceindustries.com/",
      starts_at: "2026-11-13 17:00:00",
      ends_at: "2026-11-30 17:00:00",
      published: true
    },
    {
      title: "Luminalia 2956",
      description: "Humans and Banu celebrate the festival of lights with gifts and decorations " \
        "across the 'verse.",
      starts_at: "2026-12-10 17:00:00",
      ends_at: "2026-12-23 17:00:00",
      published: false
    }
  ].freeze

  def up
    EVENTS.each do |event|
      next if select_value("SELECT 1 FROM game_events WHERE title = #{connection.quote(event[:title])}")

      execute <<~SQL.squish
        INSERT INTO game_events
          (title, description, location, url, category, starts_at, ends_at, published, created_at, updated_at)
        VALUES (
          #{connection.quote(event[:title])}, #{connection.quote(event[:description])}, #{connection.quote(event[:location])},
          #{connection.quote(event[:url])}, #{OTHER}, #{connection.quote(event[:starts_at])}, #{connection.quote(event[:ends_at])},
          #{connection.quote(event[:published])}, NOW(), NOW()
        )
      SQL
    end
  end

  def down
    execute "DELETE FROM game_events WHERE title IN (#{EVENTS.map { |event| connection.quote(event[:title]) }.join(", ")})"
  end
end
