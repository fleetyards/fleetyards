# frozen_string_literal: true

require "test_helper"
require "discord/event_availability"

module Discord
  class EventAvailabilityDstTest < ActiveSupport::TestCase
    # 18:00 in New York is 23:00 UTC in winter and 22:00 UTC in summer.
    test "an occurrence across a daylight-saving change keeps its local time" do
      ny = ActiveSupport::TimeZone["America/New_York"]
      event = build(:fleet_event, timezone: "America/New_York", starts_at: ny.local(2026, 3, 1, 18, 0), recurring: true, recurrence_interval: "weekly")

      starts_at = EventAvailability.new(event, occurrence_date: Date.new(2026, 3, 15)).starts_at

      assert_equal ny.local(2026, 3, 15, 18, 0), starts_at
    end
  end
end
