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

    test "says every how many weeks and on which days a custom series repeats" do
      @event.update!(starts_at: Time.zone.parse("2026-10-08 20:00"), timezone: "UTC",
        recurring: true, recurrence_interval: "weekly", recurrence_every: 3, recurrence_weekdays: [2])

      assert_includes content, "Every 3 weeks on Tue and Thu"
    end

    test "a series published after its first date announces its next occurrence" do
      @event.update_columns(starts_at: 9.days.ago, recurring: true, recurrence_interval: "weekly", recurrence_count: 10)
      upcoming = @event.reload.occurrences(from: Time.current, to: 2.weeks.from_now).first

      assert_includes content, "<t:#{upcoming.to_i}:F>"
    end

    test "a series whose next occurrence is over a year away still announces it" do
      @event.update_columns(starts_at: 1.day.ago, recurring: true, recurrence_interval: "monthly", recurrence_every: 18)
      publication = EventPublished.new(event: @event.reload)

      assert_predicate publication, :upcoming?
      assert_includes publication.content, "<t:#{(@event.starts_at + 18.months).to_i}:F>"
    end

    test "a series that has run out has nothing to announce" do
      @event.update_columns(starts_at: 3.weeks.ago, recurring: true, recurrence_interval: "weekly", recurrence_count: 2)

      assert_not EventPublished.new(event: @event.reload).upcoming?
    end

    test "a one-off already over has nothing to announce" do
      @event.update_columns(starts_at: 1.hour.ago)

      assert_not EventPublished.new(event: @event).upcoming?
    end

    test "shows an uploaded cover and keeps the link from unfurling a second copy" do
      @event.cover_image.attach(io: file_fixture("image.jpg").open, filename: "cover.jpg", content_type: "image/jpeg")
      publication = EventPublished.new(event: @event)

      assert_match %r{\Ahttps?://.+/rails/active_storage/representations/}, publication.image_url
      assert_includes publication.content, "<http"
    end

    test "a cover that cannot be read leaves the image out and still announces" do
      @event.cover_image.attach(io: file_fixture("image.jpg").open, filename: "cover.jpg", content_type: "image/jpeg")
      ActiveStorage::VariantWithRecord.any_instance.stubs(:processed).raises(ActiveStorage::FileNotFoundError)
      Appsignal.expects(:report_error)
      publication = EventPublished.new(event: @event)

      assert_nil publication.image_url
      assert_includes publication.content, "/fleets/#{@fleet.slug}/events/#{@event.slug}"
    end

    test "falls back to the preset art the event shows" do
      ActionController::Base.helpers.stubs(:vite_asset_url).returns("https://cdn.example/images/missions/mining.jpg")
      @event.update!(cover_image_preset: "mining")

      assert_equal "https://cdn.example/images/missions/mining.jpg", EventPublished.new(event: @event).image_url
    end

    test "leaves the image out when the preset has no absolute URL" do
      ActionController::Base.helpers.stubs(:vite_asset_url).returns("/vite-test/images/missions/mining.jpg")

      publication = EventPublished.new(event: @event)

      assert_nil publication.image_url
      assert_not_includes publication.content, "<http"
    end

    test "queues the cover alongside the message" do
      @fleet.create_fleet_notification_setting!(discord_webhook_url: "https://discord.com/api/webhooks/1/token")
      ActionController::Base.helpers.stubs(:vite_asset_url).returns("https://cdn.example/images/missions/other.jpg")
      DeliverAnnouncementJob.expects(:perform_async).with(@fleet.id, "fleet", nil, anything, @event.id, false, "https://cdn.example/images/missions/other.jpg")

      EventPublished.new(event: @event).run
    end

    test "a single event says nothing about repeating" do
      assert_not_includes content, I18n.t("discord.event_published.recurrence.weekly")
    end
  end
end
