# frozen_string_literal: true

require "test_helper"
require "discord/weekly_digest"

module Discord
  class WeeklyDigestTest < ActiveSupport::TestCase
    setup do
      @fleet = create(:fleet, name: "Test Wing")
      @setting = @fleet.create_fleet_notification_setting!(
        discord_guild_id: "900000000000000000",
        discord_announcement_channel_id: "111111111111111111"
      )
      ApiClient.stubs(:configured?).returns(true)
    end

    def event(**attributes)
      create(:fleet_event, :open, fleet: @fleet, starts_at: 2.days.from_now, **attributes)
    end

    def squadron(name, channel_id)
      create(:fleet_squadron, fleet: @fleet, name: name, discord_channel_id: channel_id)
    end

    # Keyed by where it goes: "fleet", or a squadron's channel id.
    def deliveries
      WeeklyDigest.new(@fleet).deliveries.map { |target, content| [target.channel_id || target.kind, content] }.to_h
    end

    test "lists the week's fleet-wide events in the fleet's channel" do
      event(title: "Strike Op")
      event(title: "Far Off", starts_at: 10.days.from_now)

      content = deliveries.fetch("fleet")

      assert_includes content, I18n.t("discord.weekly_digest.heading", fleet: "Test Wing")
      assert_includes content, "Strike Op"
      assert_not_includes content, "Far Off"
    end

    # The fleet channel is read by the whole fleet.
    test "a squadron's event is listed in its own channel and not the fleet's" do
      alpha = squadron("Alpha", "222222222222222222")
      event(title: "Strike Op")
      event(title: "Wing Op", visibility: "squadron", fleet_squadrons: [alpha])

      result = deliveries

      assert_not_includes result.fetch("fleet"), "Wing Op"
      assert_includes result.fetch("222222222222222222"), "Wing Op"
      assert_not_includes result.fetch("222222222222222222"), "Strike Op"
    end

    test "a channel with nothing in the week gets no post" do
      squadron("Alpha", "222222222222222222")

      assert_empty deliveries
    end

    test "each occurrence of a weekly series in the window is listed" do
      event(title: "Weekly Op", starts_at: 1.day.from_now, recurring: true, recurrence_interval: "daily", recurrence_count: 30)

      assert_equal 7, deliveries.fetch("fleet").scan("Weekly Op").size
    end

    test "drafts and cancelled events are not listed" do
      create(:fleet_event, fleet: @fleet, title: "Draft Op", starts_at: 2.days.from_now)
      event(title: "Called Off").tap { |called_off| called_off.update_column(:status, "cancelled") }

      assert_empty deliveries
    end

    test "run queues one post per channel" do
      alpha = squadron("Alpha", "222222222222222222")
      event(title: "Strike Op")
      event(title: "Wing Op", visibility: "squadron", fleet_squadrons: [alpha])
      DeliverAnnouncementJob.clear

      WeeklyDigest.new(@fleet).run

      assert_equal [["fleet", nil], ["squadron", "222222222222222222"]],
        DeliverAnnouncementJob.jobs.map { |job| job["args"][1, 2] }.sort_by(&:first)
    end

    test "a busy week is cut short under Discord's limit and links the rest" do
      40.times { |index| event(title: "Operation #{"x" * 40} #{index}") }

      content = deliveries.fetch("fleet")

      assert_operator content.length, :<=, WeeklyDigest::MAX_LENGTH
      assert_includes content, "/fleets/#{@fleet.slug}/events/"
      assert_match(/…/, content.lines.last)
    end
  end
end
