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

    test "an officers' event is listed in the officers' channel only" do
      @setting.update!(discord_officers_channel_id: "555555555555555555")
      event(title: "Strike Op")
      event(title: "Staff Meeting", visibility: "officers")

      result = deliveries

      assert_not_includes result.fetch("fleet"), "Staff Meeting"
      assert_includes result.fetch("officers"), "Staff Meeting"
      assert_not_includes result.fetch("officers"), "Strike Op"
    end

    test "an officers' event is not listed anywhere without an officers' channel" do
      event(title: "Staff Meeting", visibility: "officers")

      assert_empty deliveries
    end

    test "a channel with nothing in the week gets no post" do
      squadron("Alpha", "222222222222222222")

      assert_empty deliveries
    end

    test "each occurrence of a weekly series in the window is listed" do
      event(title: "Weekly Op", starts_at: 1.day.from_now, recurring: true, recurrence_interval: "daily", recurrence_count: 30)

      assert_equal 7, deliveries.fetch("fleet").scan("Weekly Op").size
    end

    test "each occurrence of a series links its own date" do
      event(title: "Daily Op", starts_at: 1.day.from_now, recurring: true, recurrence_interval: "daily", recurrence_count: 3)

      dates = deliveries.fetch("fleet").scan(/occurrence=(\d{4}-\d{2}-\d{2})/).flatten

      assert_equal 3, dates.uniq.size
    end

    test "counts length the way Discord does, so emoji cannot push it over" do
      30.times { |index| event(title: "🚀" * 60 + index.to_s) }

      content = deliveries.fetch("fleet")

      assert MessageLength.fits?(content), "#{MessageLength.of(content)} UTF-16 units"
    end

    # Evening in Los Angeles is already tomorrow in UTC.
    test "a series ending today in its own zone is still listed after UTC midnight" do
      travel_to Time.utc(2026, 10, 1, 1, 0) do
        la = ActiveSupport::TimeZone["America/Los_Angeles"]
        create(:fleet_event, :open, fleet: @fleet, title: "Last Op", timezone: "America/Los_Angeles",
          starts_at: la.local(2026, 9, 23, 19, 0), recurring: true, recurrence_interval: "weekly",
          recurrence_until: Date.new(2026, 9, 30))

        assert_includes deliveries.fetch("fleet"), "Last Op"
      end
    end

    # The instant the event page shows, not one rebuilt from a date.
    test "lists each occurrence at its own start" do
      series = event(title: "Weekly Op", starts_at: 1.day.from_now, recurring: true, recurrence_interval: "weekly", recurrence_count: 3)
      start = series.occurrences(from: Time.current, to: 8.days.from_now).first

      assert_includes deliveries.fetch("fleet"), "<t:#{start.to_i}:f>"
    end

    test "a channel's post looks up only its own events" do
      alpha = squadron("Alpha", "222222222222222222")
      event(title: "Strike Op")
      event(title: "Wing Op", visibility: "squadron", fleet_squadrons: [alpha])
      EventAvailability.expects(:new).once.returns(stub(cancelled?: false, title: "Wing Op", label: nil))

      content = WeeklyDigest.new(@fleet).content_for_target(AnnouncementTarget.squadron("222222222222222222"))

      assert_includes content, "Wing Op"
    end

    test "a very long fleet name still leaves room for the link to the rest" do
      @fleet.update_column(:name, "x" * 1990)
      40.times { |index| event(title: "Operation #{index}") }

      content = deliveries.fetch("fleet")

      assert MessageLength.fits?(content)
      assert_includes content, "/fleets/#{@fleet.slug}/events/"
    end

    test "an occurrence cancelled by its status alone is not listed" do
      series = event(title: "Daily Op", starts_at: 1.day.from_now, recurring: true, recurrence_interval: "daily", recurrence_count: 2)
      first = series.occurrences(from: Time.current, to: 3.days.from_now).first
      series.fleet_event_occurrence_states.create!(occurrence_date: first.to_date, status: "cancelled")

      assert_equal 1, deliveries.fetch("fleet").scan("Daily Op").size
    end

    # A title holding `](` must not open a link of its own.
    test "a title cannot rewrite the link it sits in" do
      event(title: "Op](https://evil.example/")

      content = deliveries.fetch("fleet")

      assert_includes content, "[Op\\]\\(https://evil.example/](https://"
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

    test "a list that fits is posted whole, without a footer" do
      3.times { |index| event(title: "Operation #{index}") }

      content = deliveries.fetch("fleet")

      assert_equal 3, content.scan("Operation").size
      assert_not_includes content, "…"
    end

    # The footer's own length depends on how many it counts; the one sent has
    # to be the one measured.
    test "never exceeds the limit whatever the footer ends up counting" do
      digest = WeeklyDigest.new(@fleet)
      heading = I18n.t("discord.weekly_digest.heading", fleet: "Test Wing")

      (1..60).each do |size|
        listed = Array.new(size) { |index| {event: FleetEvent.new(slug: "e#{index}"), starts_at: Time.current, title: "x" * (20 + (index % 7)), availability: nil} }
        content = digest.send(:content_for, listed)

        assert_operator content.length, :<=, WeeklyDigest::MAX_LENGTH, "#{size} events"
        assert content.start_with?(heading)
      end
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
