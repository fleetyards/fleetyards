# frozen_string_literal: true

require "rails_helper"

RSpec.describe Notifications::FleetEventStartingSoonJob do
  describe "#perform" do
    let(:fleet) { create(:fleet) }

    it "notifies one-off events whose start is within the window" do
      event = create(:fleet_event, :open,
        fleet: fleet, starts_at: 20.minutes.from_now)

      events = []
      subscriber = ActiveSupport::Notifications.subscribe("fleet_event.starting_soon") do |*args|
        events << ActiveSupport::Notifications::Event.new(*args)
      end

      begin
        described_class.new.perform
      ensure
        ActiveSupport::Notifications.unsubscribe(subscriber)
      end

      expect(events.size).to eq(1)
      expect(events.first.payload[:event]).to eq(event)
      expect(event.reload.starting_soon_notified_at).to be_present
    end

    it "skips one-off events already notified" do
      create(:fleet_event, :open,
        fleet: fleet, starts_at: 20.minutes.from_now,
        starting_soon_notified_at: 1.minute.ago)

      events = []
      subscriber = ActiveSupport::Notifications.subscribe("fleet_event.starting_soon") do |*args|
        events << ActiveSupport::Notifications::Event.new(*args)
      end

      begin
        described_class.new.perform
      ensure
        ActiveSupport::Notifications.unsubscribe(subscriber)
      end

      expect(events).to be_empty
    end

    context "recurring events" do
      it "notifies the next occurrence within the window and marks its state" do
        event = create(:fleet_event, :open,
          fleet: fleet,
          recurring: true, recurrence_interval: "weekly",
          starts_at: 20.minutes.from_now)

        events = []
        subscriber = ActiveSupport::Notifications.subscribe("fleet_event.starting_soon") do |*args|
          events << ActiveSupport::Notifications::Event.new(*args)
        end

        begin
          described_class.new.perform
        ensure
          ActiveSupport::Notifications.unsubscribe(subscriber)
        end

        expect(events.size).to eq(1)
        expect(events.first.payload[:occurrence_date]).to eq(event.starts_at.to_date)
        expect(event.fleet_event_occurrence_states.first.starting_soon_notified_at)
          .to be_present
      end

      it "is idempotent for the same occurrence" do
        event = create(:fleet_event, :open,
          fleet: fleet,
          recurring: true, recurrence_interval: "weekly",
          starts_at: 20.minutes.from_now)

        described_class.new.perform
        first_at = event.fleet_event_occurrence_states.first.starting_soon_notified_at

        described_class.new.perform

        expect(event.fleet_event_occurrence_states.first.reload.starting_soon_notified_at)
          .to eq(first_at)
      end
    end
  end
end
