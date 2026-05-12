# frozen_string_literal: true

require "rails_helper"

RSpec.describe FleetEvents::AutoLockJob do
  describe "#perform" do
    let(:fleet) { create(:fleet) }

    it "locks open events whose auto-lock window has begun" do
      event = create(:fleet_event, :open,
        fleet: fleet,
        auto_lock_enabled: true,
        auto_lock_minutes_before: 60,
        starts_at: 30.minutes.from_now)

      described_class.new.perform

      expect(event.reload.status).to eq("locked")
    end

    it "leaves open events whose window hasn't started yet" do
      event = create(:fleet_event, :open,
        fleet: fleet,
        auto_lock_enabled: true,
        auto_lock_minutes_before: 60,
        starts_at: 3.hours.from_now)

      described_class.new.perform

      expect(event.reload.status).to eq("open")
    end

    it "skips events with auto-lock disabled" do
      event = create(:fleet_event, :open,
        fleet: fleet,
        auto_lock_enabled: false,
        auto_lock_minutes_before: 60,
        starts_at: 10.minutes.from_now)

      described_class.new.perform

      expect(event.reload.status).to eq("open")
    end

    it "skips events not in the open state" do
      locked = create(:fleet_event, :locked,
        fleet: fleet,
        auto_lock_enabled: true,
        starts_at: 5.minutes.from_now)
      active = create(:fleet_event, :active,
        fleet: fleet,
        auto_lock_enabled: true,
        starts_at: 5.minutes.ago)

      expect { described_class.new.perform }
        .not_to(change { [locked.reload.status, active.reload.status] })
    end

    it "still locks events whose start time has already passed" do
      event = create(:fleet_event, :open,
        fleet: fleet,
        auto_lock_enabled: true,
        auto_lock_minutes_before: 60,
        starts_at: 10.minutes.ago)

      described_class.new.perform

      expect(event.reload.status).to eq("locked")
    end

    it "fires the fleet_event.locked notification for each locked event" do
      event = create(:fleet_event, :open,
        fleet: fleet,
        auto_lock_enabled: true,
        auto_lock_minutes_before: 60,
        starts_at: 5.minutes.from_now)

      events = []
      subscriber = ActiveSupport::Notifications.subscribe("fleet_event.locked") do |*args|
        events << ActiveSupport::Notifications::Event.new(*args)
      end

      begin
        described_class.new.perform
      ensure
        ActiveSupport::Notifications.unsubscribe(subscriber)
      end

      expect(events.size).to eq(1)
      expect(events.first.payload[:event]).to eq(event)
    end
  end
end
