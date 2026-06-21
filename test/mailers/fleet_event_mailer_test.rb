# frozen_string_literal: true

require "test_helper"

class FleetEventMailerTest < ActionMailer::TestCase
  setup do
    @user = create(:user, email: "member@example.com")
    @fleet = create(:fleet, name: "Stellar Wings")
    @event = create(:fleet_event, fleet: @fleet, title: "Bunker run")
  end

  class PublishedTest < FleetEventMailerTest
    setup do
      @notification = create(
        :notification,
        user: @user,
        notification_type: "fleet_event_published",
        title: "New event in Stellar Wings: Bunker run",
        record: @event
      )
    end

    test "renders the localized subject with the event title" do
      mail = FleetEventMailer.published(@notification)
      assert_equal I18n.t("mailer.fleet_event.published.subject", title: @event.title), mail.subject
    end

    test "addresses the recipient by their email" do
      mail = FleetEventMailer.published(@notification)
      assert_equal [@user.email], mail.to
    end

    test "embeds the notification title in the body" do
      mail = FleetEventMailer.published(@notification)
      assert_includes mail.body.encoded, @notification.title
    end

    test "links to the event detail page" do
      mail = FleetEventMailer.published(@notification)
      assert_includes mail.body.encoded, "/fleets/#{@fleet.slug}/events/#{@event.slug}"
    end
  end

  class CancelledTest < FleetEventMailerTest
    setup do
      @notification = create(
        :notification,
        user: @user,
        notification_type: "fleet_event_cancelled",
        title: "Event cancelled: Bunker run",
        body: "Server hot-fix; will reschedule.",
        record: @event
      )
    end

    test "includes the cancellation reason from notification body" do
      mail = FleetEventMailer.cancelled(@notification)
      assert_includes mail.body.encoded, "Server hot-fix; will reschedule."
    end

    test "uses the cancelled subject" do
      mail = FleetEventMailer.cancelled(@notification)
      assert_equal I18n.t("mailer.fleet_event.cancelled.subject", title: @event.title), mail.subject
    end
  end
end
