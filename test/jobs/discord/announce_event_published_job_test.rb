# frozen_string_literal: true

require "test_helper"

module Discord
  class AnnounceEventPublishedJobTest < ActiveSupport::TestCase
    setup do
      @fleet = create(:fleet)
      @event = create(:fleet_event, :open, fleet: @fleet, starts_at: 2.days.from_now)
    end

    test "announces an upcoming event" do
      EventPublished.any_instance.expects(:run)

      AnnounceEventPublishedJob.new.perform(@event.id)
    end

    # Narrowed while still a draft.
    test "announces nothing for a draft" do
      @event.update_column(:status, "draft")
      EventPublished.any_instance.expects(:run).never

      AnnounceEventPublishedJob.new.perform(@event.id)
    end

    test "announces nothing for an event already over" do
      @event.update_column(:starts_at, 1.hour.ago)
      EventPublished.any_instance.expects(:run).never

      AnnounceEventPublishedJob.new.perform(@event.id)
    end
  end
end
