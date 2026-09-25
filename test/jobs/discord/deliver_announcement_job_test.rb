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

    # Built when it posts, so an event cancelled meanwhile is not listed.
    test "builds a digest post from the week as it is when it runs" do
      @fleet.fleet_notification_setting.update!(discord_digest_weekday: 1, discord_digest_time: "18:00")
      @event.update_columns(title: "Strike Op", starts_at: 2.days.from_now)
      create(:fleet_event, :open, fleet: @fleet, title: "Mining Run", starts_at: 3.days.from_now)
      @event.update_column(:status, "cancelled")
      AnnouncementTarget.any_instance.expects(:deliver).with(@fleet, all_of(includes("Mining Run"), Not(includes("Strike Op"))))

      DeliverAnnouncementJob.new.perform(@fleet.id, "fleet", nil, nil, nil, true)
    end

    # Last week's post, still queued when this week's was claimed.
    test "posts no digest for a week that has been claimed again since" do
      last_week = 1.week.ago.floor(6)
      @fleet.fleet_notification_setting.update!(discord_digest_weekday: 1, discord_digest_time: "18:00", discord_digest_sent_at: Time.current.floor(6))
      AnnouncementTarget.any_instance.expects(:deliver).never

      DeliverAnnouncementJob.new.perform(@fleet.id, "fleet", nil, nil, nil, last_week.iso8601(6))
    end

    test "posts no digest once it was rescheduled after being queued" do
      claimed_at = Time.utc(2026, 9, 21, 18, 5)
      @fleet.fleet_notification_setting.update!(
        discord_digest_weekday: 2, discord_digest_time: "18:00", discord_digest_sent_at: claimed_at
      )
      AnnouncementTarget.any_instance.expects(:deliver).never

      travel_to(claimed_at + 1.minute) do
        DeliverAnnouncementJob.new.perform(@fleet.id, "fleet", nil, nil, nil, claimed_at.iso8601(6))
      end
    end

    test "posts no digest when nothing is left in the week" do
      @fleet.fleet_notification_setting.update!(discord_digest_weekday: 1, discord_digest_time: "18:00")
      @event.update_column(:status, "cancelled")
      AnnouncementTarget.any_instance.expects(:deliver).never

      DeliverAnnouncementJob.new.perform(@fleet.id, "fleet", nil, nil, nil, true)
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
