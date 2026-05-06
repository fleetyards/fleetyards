# frozen_string_literal: true

require "rails_helper"
require "discord/scheduled_event_rsvp_handler"

RSpec.describe Discord::ScheduledEventRsvpHandler do
  let(:fleet) { create(:fleet) }
  let(:user) { create(:user) }
  let!(:omniauth) do
    create(:omniauth_connection, user: user, provider: "discord", uid: "discord-uid-1")
  end
  let!(:setting) do
    fleet.create_fleet_notification_setting!(discord_guild_id: "guild-1")
  end
  let!(:event) do
    create(:fleet_event, :open, fleet: fleet, discord_event_id: "scheduled-1")
  end
  let!(:membership) do
    fm = fleet.fleet_memberships.create!(user: user, fleet_role: fleet.fleet_roles.ranked.last)
    fm.update!(aasm_state: "accepted")
    fm
  end

  describe "#add!" do
    it "creates an event-level confirmed signup" do
      handler = described_class.new(
        guild_id: "guild-1",
        scheduled_event_id: "scheduled-1",
        discord_user_id: "discord-uid-1"
      )

      result = handler.add!
      expect(result.ok?).to be(true), "expected ok, got #{result.status}: #{result.detail}"
      signup = event.fleet_event_signups.find_by(fleet_membership: membership)
      expect(signup.status).to eq("confirmed")
      expect(signup.fleet_event_slot_id).to be_nil
    end

    it "promotes an existing interested signup to confirmed" do
      event.fleet_event_signups.create!(
        fleet_membership: membership,
        fleet_event_slot: nil,
        status: "interested"
      )

      handler = described_class.new(
        guild_id: "guild-1",
        scheduled_event_id: "scheduled-1",
        discord_user_id: "discord-uid-1"
      )
      result = handler.add!

      expect(result.ok?).to be true
      expect(event.fleet_event_signups.where(fleet_membership: membership).where.not(status: "withdrawn").count).to eq(1)
      expect(event.fleet_event_signups.find_by(fleet_membership: membership).status).to eq("confirmed")
    end

    it "skips when the user has no Discord connection" do
      handler = described_class.new(
        guild_id: "guild-1",
        scheduled_event_id: "scheduled-1",
        discord_user_id: "unknown"
      )
      expect(handler.add!).to have_attributes(status: :skipped)
    end

    it "skips when the guild id doesn't match the fleet binding" do
      handler = described_class.new(
        guild_id: "wrong-guild",
        scheduled_event_id: "scheduled-1",
        discord_user_id: "discord-uid-1"
      )
      expect(handler.add!).to have_attributes(status: :skipped)
    end

    it "skips when the user isn't an accepted member" do
      membership.update!(aasm_state: "invited")
      handler = described_class.new(
        guild_id: "guild-1",
        scheduled_event_id: "scheduled-1",
        discord_user_id: "discord-uid-1"
      )
      expect(handler.add!).to have_attributes(status: :skipped)
    end
  end

  describe "#remove!" do
    it "withdraws the existing signup" do
      signup = event.fleet_event_signups.create!(
        fleet_membership: membership,
        fleet_event_slot: nil,
        status: "confirmed"
      )

      handler = described_class.new(
        guild_id: "guild-1",
        scheduled_event_id: "scheduled-1",
        discord_user_id: "discord-uid-1"
      )
      expect(handler.remove!.ok?).to be true
      expect(signup.reload.status).to eq("withdrawn")
    end

    it "is a no-op when nothing is signed up" do
      handler = described_class.new(
        guild_id: "guild-1",
        scheduled_event_id: "scheduled-1",
        discord_user_id: "discord-uid-1"
      )
      expect(handler.remove!).to have_attributes(status: :skipped)
    end
  end
end
