# frozen_string_literal: true

require "rails_helper"
require "discord/api_client"

RSpec.describe Notifications::Discord::FleetEventSubscriber do
  let(:fleet) { create(:fleet) }
  let(:event) { create(:fleet_event, :open, fleet: fleet) }

  before do
    fleet.create_fleet_notification_setting!(discord_guild_id: "123")
    allow(Discord::ApiClient).to receive(:configured?).and_return(true)
  end

  it "enqueues an upsert job on a publish-class event" do
    expect(Discord::SyncFleetEventJob).to receive(:perform_async)
      .with(event.id, "action" => "upsert")

    described_class.new("fleet_event.published", {event: event}).call
  end

  it "enqueues a delete job on archived/destroyed events" do
    expect(Discord::SyncFleetEventJob).to receive(:perform_async)
      .with(event.id, "action" => "delete")

    described_class.new("fleet_event.archived", {event: event}, action: :delete).call
  end

  it "skips silently when the bot token is missing" do
    allow(Discord::ApiClient).to receive(:configured?).and_return(false)
    expect(Discord::SyncFleetEventJob).not_to receive(:perform_async)

    described_class.new("fleet_event.published", {event: event}).call
  end

  it "skips silently when the fleet hasn't connected Discord" do
    fleet.fleet_notification_setting.update!(discord_guild_id: nil)
    expect(Discord::SyncFleetEventJob).not_to receive(:perform_async)

    described_class.new("fleet_event.published", {event: event}).call
  end
end
