# frozen_string_literal: true

require "rails_helper"
require "discord/scheduled_event_sync"

RSpec.describe Discord::ScheduledEventSync do
  let(:fleet) { create(:fleet) }
  let!(:setting) do
    fleet.create_fleet_notification_setting!(
      discord_guild_id: "123456789",
      enabled_in_app_events: FleetNotificationSetting::DEFAULT_IN_APP_EVENTS
    )
  end
  let(:event) do
    create(:fleet_event, :open,
      fleet: fleet,
      title: "Strike Op",
      starts_at: 2.days.from_now,
      ends_at: 2.days.from_now + 2.hours)
  end
  let(:api) { instance_double(Discord::ApiClient) }

  before do
    allow(Discord::ApiClient).to receive(:configured?).and_return(true)
    allow(Discord::ApiClient).to receive(:new).and_return(api)
  end

  describe "#runnable?" do
    it "is false when the bot token is missing" do
      allow(Discord::ApiClient).to receive(:configured?).and_return(false)
      expect(described_class.new(event).runnable?).to be false
    end

    it "is false when the fleet has no Discord guild" do
      setting.update!(discord_guild_id: nil)
      expect(described_class.new(event).runnable?).to be false
    end

    it "is true when both are present" do
      expect(described_class.new(event).runnable?).to be true
    end
  end

  describe "#upsert!" do
    it "creates a Discord scheduled event when discord_event_id is missing" do
      allow(api).to receive(:create_guild_scheduled_event)
        .with("123456789", hash_including(name: "Strike Op", privacy_level: 2, entity_type: 3))
        .and_return("id" => "999")

      described_class.new(event).upsert!

      expect(event.reload.discord_event_id).to eq("999")
      expect(event.reload.discord_synced_at).not_to be_nil
    end

    it "uses entity_type voice when a channel is configured" do
      setting.update!(discord_channel_id: "555")
      allow(api).to receive(:create_guild_scheduled_event)
        .with("123456789", hash_including(entity_type: 2, channel_id: "555"))
        .and_return("id" => "999")

      described_class.new(event).upsert!
    end

    it "patches the existing Discord event when discord_event_id is set" do
      event.update_column(:discord_event_id, "888")
      allow(api).to receive(:update_guild_scheduled_event)
        .with("123456789", "888", hash_including(name: "Strike Op"))
        .and_return("id" => "888")

      described_class.new(event).upsert!
      expect(event.reload.discord_event_id).to eq("888")
    end

    it "marks the event completed when status is cancelled" do
      event.update!(status: "cancelled")
      allow(api).to receive(:create_guild_scheduled_event)
        .with("123456789", hash_including(status: 4))
        .and_return("id" => "999")

      described_class.new(event).upsert!
    end

    it "resets and retries when Discord 404s a stale event id" do
      event.update_column(:discord_event_id, "stale")
      call_count = 0
      allow(api).to receive(:update_guild_scheduled_event) do
        call_count += 1
        raise Discord::ApiClient::Error.new(404, "Unknown event")
      end
      allow(api).to receive(:create_guild_scheduled_event).and_return("id" => "fresh")

      described_class.new(event).upsert!
      expect(event.reload.discord_event_id).to eq("fresh")
      expect(call_count).to eq(1)
    end
  end

  describe "description payload" do
    let(:creator) { create(:user, username: "TorlekMaru") }
    let(:starts_at) { 2.days.from_now }
    let(:event) do
      create(:fleet_event, :open,
        fleet: fleet,
        created_by: creator,
        title: "Strike Op",
        description: "Briefing body.",
        starts_at: starts_at)
    end

    let(:captured) { {} }
    before do
      allow(api).to receive(:create_guild_scheduled_event) do |_guild, payload|
        captured.merge!(payload)
        {"id" => "999"}
      end
    end

    it "puts the Sesh-style chip line first so it survives the card preview truncation" do
      described_class.new(event).upsert!
      expect(captured[:description].lines.first).to start_with("🚩 ")
    end

    it "renders the host as a Discord @-mention when the creator linked Discord" do
      create(:omniauth_connection, user: creator, provider: "discord", uid: "344036297326723073")

      described_class.new(event).upsert!
      expect(captured[:description]).to include("🚩 <@344036297326723073>")
    end

    it "falls back to the plain handle when Discord isn't linked" do
      described_class.new(event).upsert!
      expect(captured[:description]).to include("🚩 TorlekMaru")
      expect(captured[:description]).not_to include("<@")
    end

    it "shows confirmed and interested counts in Sesh's `N (+M)` format" do
      create_list(:fleet_event_signup, 2, fleet_event: event, fleet_event_slot: nil, status: "confirmed")
      create_list(:fleet_event_signup, 3, fleet_event: event, fleet_event_slot: nil, status: "interested")
      create(:fleet_event_signup, fleet_event: event, fleet_event_slot: nil, status: "withdrawn")

      described_class.new(event).upsert!
      expect(captured[:description]).to include("👥 2 (+3)")
    end

    it "uses Discord's `<t:UNIX:R>` tag for the relative-time chip" do
      described_class.new(event).upsert!
      expect(captured[:description]).to include("⏳ <t:#{starts_at.to_i}:R>")
    end

    it "wraps the short URL in <> to suppress Discord's link preview" do
      described_class.new(event).upsert!
      expect(captured[:description]).to match(%r{\*\*Open in Fleetyards:\*\* <https?://[^>]+/fe/})
    end
  end

  describe "external location chip" do
    let(:event) { create(:fleet_event, :open, fleet: fleet, meetup_location: "Lorville Outpost") }

    let(:captured) { {} }
    before do
      allow(api).to receive(:create_guild_scheduled_event) do |_guild, payload|
        captured.merge!(payload)
        {"id" => "999"}
      end
    end

    it "uses the in-game meetup location when set" do
      described_class.new(event).upsert!
      expect(captured[:entity_metadata][:location]).to eq("Lorville Outpost")
    end

    it "falls back to 'Star Citizen' when neither meetup_location nor location is set" do
      event.update!(meetup_location: nil, location: nil)

      described_class.new(event).upsert!
      expect(captured[:entity_metadata][:location]).to eq("Star Citizen")
    end
  end

  describe "#delete!" do
    it "deletes the Discord event and clears local references" do
      event.update_column(:discord_event_id, "777")
      allow(api).to receive(:delete_guild_scheduled_event).with("123456789", "777")

      described_class.new(event).delete!
      expect(event.reload.discord_event_id).to be_nil
    end

    it "is a no-op when there is no discord_event_id" do
      expect(api).not_to receive(:delete_guild_scheduled_event)
      described_class.new(event).delete!
    end

    it "swallows 404s when Discord already lost the event" do
      event.update_column(:discord_event_id, "777")
      allow(api).to receive(:delete_guild_scheduled_event)
        .and_raise(Discord::ApiClient::Error.new(404, "Unknown event"))

      expect { described_class.new(event).delete! }.not_to raise_error
      expect(event.reload.discord_event_id).to be_nil
    end
  end
end
