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

    test "a series published after its first date announces its next occurrence" do
      @event.update_columns(starts_at: 9.days.ago, recurring: true, recurrence_interval: "weekly", recurrence_count: 10)
      upcoming = @event.reload.occurrences(from: Time.current, to: 2.weeks.from_now).first

      assert_includes content, "<t:#{upcoming.to_i}:F>"
    end

    test "a single event says nothing about repeating" do
      assert_not_includes content, I18n.t("discord.event_published.recurrence.weekly")
    end
  end
end
