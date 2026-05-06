# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Discord status probe", type: :request do
  let(:admin) { create(:user) }
  let(:fleet) { create(:fleet, admins: [admin]) }
  let(:url) { "/api/v1/fleets/#{fleet.slug}/notifications/discord-status" }

  before { sign_in(admin) }

  it "reports missing_token when the bot token isn't configured" do
    allow(Discord::ApiClient).to receive(:configured?).and_return(false)

    get url, as: :json
    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)
    expect(body["ok"]).to eq(false)
    expect(body["code"]).to eq("missing_token")
  end

  it "reports missing_guild when no guild id is set" do
    allow(Discord::ApiClient).to receive(:configured?).and_return(true)

    get url, as: :json
    body = JSON.parse(response.body)
    expect(body["ok"]).to eq(false)
    expect(body["code"]).to eq("missing_guild")
  end

  it "reports ok and the guild name on success" do
    fleet.create_fleet_notification_setting!(discord_guild_id: "guild-1")
    api = instance_double(Discord::ApiClient, get_guild: {"id" => "guild-1", "name" => "Test Server"})
    allow(Discord::ApiClient).to receive(:configured?).and_return(true)
    allow(Discord::ApiClient).to receive(:new).and_return(api)

    get url, as: :json
    body = JSON.parse(response.body)
    expect(body["ok"]).to eq(true)
    expect(body["guildName"]).to eq("Test Server")
  end

  it "reports bot_not_in_guild on a 403" do
    fleet.create_fleet_notification_setting!(discord_guild_id: "guild-1")
    api = instance_double(Discord::ApiClient)
    allow(api).to receive(:get_guild).and_raise(Discord::ApiClient::Error.new(403, "missing access"))
    allow(Discord::ApiClient).to receive(:configured?).and_return(true)
    allow(Discord::ApiClient).to receive(:new).and_return(api)

    get url, as: :json
    body = JSON.parse(response.body)
    expect(body["ok"]).to eq(false)
    expect(body["code"]).to eq("bot_not_in_guild")
  end

  it "reports guild_not_found on a 404" do
    fleet.create_fleet_notification_setting!(discord_guild_id: "guild-1")
    api = instance_double(Discord::ApiClient)
    allow(api).to receive(:get_guild).and_raise(Discord::ApiClient::Error.new(404, "unknown guild"))
    allow(Discord::ApiClient).to receive(:configured?).and_return(true)
    allow(Discord::ApiClient).to receive(:new).and_return(api)

    get url, as: :json
    body = JSON.parse(response.body)
    expect(body["code"]).to eq("guild_not_found")
  end

  it "reports invalid_token on a 401" do
    fleet.create_fleet_notification_setting!(discord_guild_id: "guild-1")
    api = instance_double(Discord::ApiClient)
    allow(api).to receive(:get_guild).and_raise(Discord::ApiClient::Error.new(401, "unauthorized"))
    allow(Discord::ApiClient).to receive(:configured?).and_return(true)
    allow(Discord::ApiClient).to receive(:new).and_return(api)

    get url, as: :json
    body = JSON.parse(response.body)
    expect(body["code"]).to eq("invalid_token")
  end

  it "includes installUrl when the bot client_id is configured" do
    allow(Discord::ApiClient).to receive(:configured?).and_return(true)
    allow(Discord::ApiClient).to receive(:application_id).and_return("123456789")

    get url, as: :json
    body = JSON.parse(response.body)
    expect(body["installUrl"]).to start_with("https://discord.com/oauth2/authorize?client_id=123456789")
    expect(body["installUrl"]).to include("scope=bot+applications.commands")
  end

  it "omits installUrl when the bot client_id is not configured" do
    allow(Discord::ApiClient).to receive(:configured?).and_return(true)
    allow(Discord::ApiClient).to receive(:application_id).and_return(nil)

    get url, as: :json
    body = JSON.parse(response.body)
    expect(body["installUrl"]).to be_nil
  end
end
