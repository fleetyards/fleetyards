# frozen_string_literal: true

require "test_helper"

module Discord
  class AnnounceEventReminderJobTest < ActiveSupport::TestCase
    setup do
      @fleet = create(:fleet)
      @event = create(:fleet_event, :open, fleet: @fleet)
    end

    test "reminds the fleet of an event it can all see" do
      ::Discord::EventReminder.any_instance.expects(:run)

      ::Discord::AnnounceEventReminderJob.new.perform(@event.id)
    end

    # The webhook posts to a channel the whole fleet reads.
    test "does not announce an event held to squadrons" do
      squadron = create(:fleet_squadron, fleet: @fleet)
      @event.update!(visibility: "squadron", fleet_squadrons: [squadron])
      ::Discord::EventReminder.any_instance.expects(:run).never

      ::Discord::AnnounceEventReminderJob.new.perform(@event.id)
    end
  end
end
