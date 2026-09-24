# frozen_string_literal: true

require "test_helper"

module Discord
  class DeliverAnnouncementJobTest < ActiveSupport::TestCase
    setup do
      @fleet = create(:fleet)
      @event = create(:fleet_event, :open, fleet: @fleet)
    end

    test "posts to its target" do
      AnnouncementTarget.any_instance.expects(:deliver).with(@fleet, "hello")

      DeliverAnnouncementJob.new.perform(@fleet.id, "fleet", nil, "hello", @event.id)
    end

    test "posts nothing for an event cancelled while the post waited" do
      @event.update_column(:status, "cancelled")
      AnnouncementTarget.any_instance.expects(:deliver).never

      DeliverAnnouncementJob.new.perform(@fleet.id, "fleet", nil, "hello", @event.id)
    end

    test "posts nothing for an event archived while the post waited" do
      @event.update_column(:archived_at, Time.current)
      AnnouncementTarget.any_instance.expects(:deliver).never

      DeliverAnnouncementJob.new.perform(@fleet.id, "fleet", nil, "hello", @event.id)
    end
  end
end
