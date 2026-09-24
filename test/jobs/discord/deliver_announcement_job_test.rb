# frozen_string_literal: true

require "test_helper"

module Discord
  class DeliverAnnouncementJobTest < ActiveSupport::TestCase
    setup do
      @fleet = create(:fleet)
      @fleet.create_fleet_notification_setting!(discord_webhook_url: "https://discord.com/api/webhooks/1/token")
      @event = create(:fleet_event, :open, fleet: @fleet)
    end

    test "posts to its target" do
      AnnouncementTarget.any_instance.expects(:deliver).with(@fleet, "hello")

      DeliverAnnouncementJob.new.perform(@fleet.id, "fleet", nil, "hello", @event.id)
    end

    test "posts no digest once the digest was switched off" do
      AnnouncementTarget.any_instance.expects(:deliver).never

      DeliverAnnouncementJob.new.perform(@fleet.id, "fleet", nil, "hello", nil, true)
    end

    test "posts nothing for a deleted fleet" do
      @fleet.update_column(:discarded_at, Time.current)
      AnnouncementTarget.any_instance.expects(:deliver).never

      DeliverAnnouncementJob.new.perform(@fleet.id, "fleet", nil, "hello", @event.id)
    end

    test "posts nothing for an event cancelled while the post waited" do
      @event.update_column(:status, "cancelled")
      AnnouncementTarget.any_instance.expects(:deliver).never

      DeliverAnnouncementJob.new.perform(@fleet.id, "fleet", nil, "hello", @event.id)
    end

    test "posts nothing to the fleet for an event narrowed while the post waited" do
      @event.update_column(:visibility, "officers")
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
