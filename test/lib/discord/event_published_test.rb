# frozen_string_literal: true

require "test_helper"
require "discord/event_published"

module Discord
  class EventPublishedTest < ActiveSupport::TestCase
    setup do
      @fleet = create(:fleet)
      @event = create(:fleet_event, :open, fleet: @fleet, title: "Strike Op", starts_at: 2.days.from_now)
    end

    def content
      EventPublished.new(event: @event).content
    end

    test "names the event, links it and gives its start as a Discord timestamp" do
      assert_includes content, I18n.t("discord.event_published.title", title: "Strike Op")
      assert_includes content, "<t:#{@event.starts_at.to_i}:F>"
      assert_includes content, "/fleets/#{@fleet.slug}/events/#{@event.slug}"
    end

    test "says how often a recurring event repeats" do
      @event.update!(recurring: true, recurrence_interval: "weekly", recurrence_count: 4)

      assert_includes content, I18n.t("discord.event_published.recurrence.weekly")
    end

    test "says every how many weeks and on which days a custom series repeats" do
      @event.update!(starts_at: Time.zone.parse("2026-10-08 20:00"), timezone: "UTC",
        recurring: true, recurrence_interval: "weekly", recurrence_every: 3, recurrence_weekdays: [2])

      assert_includes content, "Every 3 weeks on Tue and Thu"
    end

    test "a series published after its first date announces its next occurrence" do
      @event.update_columns(starts_at: 9.days.ago, recurring: true, recurrence_interval: "weekly", recurrence_count: 10)
      upcoming = @event.reload.occurrences(from: Time.current, to: 2.weeks.from_now).first

      assert_includes content, "<t:#{upcoming.to_i}:F>"
    end

    test "a series that has run out has nothing to announce" do
      @event.update_columns(starts_at: 3.weeks.ago, recurring: true, recurrence_interval: "weekly", recurrence_count: 2)

      assert_not EventPublished.new(event: @event.reload).upcoming?
    end

    test "a one-off already over has nothing to announce" do
      @event.update_columns(starts_at: 1.hour.ago)

      assert_not EventPublished.new(event: @event).upcoming?
    end

    test "a single event says nothing about repeating" do
      assert_not_includes content, I18n.t("discord.event_published.recurrence.weekly")
    end
  end
end
