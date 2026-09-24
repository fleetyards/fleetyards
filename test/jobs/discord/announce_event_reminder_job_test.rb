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

    # Where it goes is Discord::EventAnnouncement's question, not the job's.
    test "reminds an event held to squadrons as well" do
      squadron = create(:fleet_squadron, fleet: @fleet)
      @event.update!(visibility: "squadron", fleet_squadrons: [squadron])
      ::Discord::EventReminder.any_instance.expects(:run)

      ::Discord::AnnounceEventReminderJob.new.perform(@event.id)
    end
  end
end
