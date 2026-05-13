# frozen_string_literal: true

require "rails_helper"

RSpec.describe FleetEventMailer do
  let(:user) { create(:user, email: "member@example.com") }
  let(:fleet) { create(:fleet, name: "Stellar Wings") }
  let(:event) { create(:fleet_event, fleet:, title: "Bunker run") }
  let(:notification) do
    create(
      :notification,
      user:,
      notification_type: "fleet_event_published",
      title: "New event in Stellar Wings: Bunker run",
      record: event
    )
  end

  describe "#published" do
    let(:mail) { described_class.published(notification) }

    it "renders the localized subject with the event title" do
      expect(mail.subject).to eq(I18n.t("mailer.fleet_event.published.subject", title: event.title))
    end

    it "addresses the recipient by their email" do
      expect(mail.to).to eq([user.email])
    end

    it "embeds the notification title in the body" do
      expect(mail.body.encoded).to include(notification.title)
    end

    it "links to the event detail page" do
      expect(mail.body.encoded).to include("/fleets/#{fleet.slug}/events/#{event.slug}")
    end
  end

  describe "#cancelled" do
    let(:notification) do
      create(
        :notification,
        user:,
        notification_type: "fleet_event_cancelled",
        title: "Event cancelled: Bunker run",
        body: "Server hot-fix; will reschedule.",
        record: event
      )
    end
    let(:mail) { described_class.cancelled(notification) }

    it "includes the cancellation reason from notification body" do
      expect(mail.body.encoded).to include("Server hot-fix; will reschedule.")
    end

    it "uses the cancelled subject" do
      expect(mail.subject).to eq(I18n.t("mailer.fleet_event.cancelled.subject", title: event.title))
    end
  end
end
