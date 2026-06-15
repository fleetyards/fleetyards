# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsEventsSyncToDiscordTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/events/{slug}/sync-to-discord" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}
    parameter name: "slug", in: :path, schema: {type: :string}

    post("Sync event to Discord") do
      operationId "syncFleetEventToDiscord"
      tags "Fleet Events"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetEventExtended"
      end

      response(422, "discord not configured") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  setup do
    Flipper.enable("mission_builder")
    @admin = create(:user)
    @fleet = create(:fleet, admins: [@admin])
  end

  def stub_discord_runnable
    @fleet.create_fleet_notification_setting!(discord_guild_id: "guild-1")
    ::Discord::ApiClient.stubs(:configured?).returns(true)
    sync = mock("Discord::ScheduledEventSync")
    sync.stubs(:runnable?).returns(true)
    sync.stubs(:upsert!).returns({"id" => "discord-1"})
    ::Discord::ScheduledEventSync.stubs(:new).returns(sync)
  end

  test "POST /fleets/:slug/events/:slug/sync-to-discord syncs to Discord" do
    fleet_event = create(:fleet_event, :open, fleet: @fleet, created_by: @admin)
    stub_discord_runnable
    sign_in @admin

    assert_api_response :post, 200, path_params: {fleetSlug: @fleet.slug, slug: fleet_event.slug}
  end

  test "POST /fleets/:slug/events/:slug/sync-to-discord returns 422 when Discord is not configured" do
    fleet_event = create(:fleet_event, :open, fleet: @fleet, created_by: @admin)
    @fleet.create_fleet_notification_setting!(discord_guild_id: "guild-1")
    ::Discord::ApiClient.stubs(:configured?).returns(false)
    sync = mock("Discord::ScheduledEventSync")
    sync.stubs(:runnable?).returns(false)
    ::Discord::ScheduledEventSync.stubs(:new).returns(sync)
    sign_in @admin

    assert_api_response :post, 422, path_params: {fleetSlug: @fleet.slug, slug: fleet_event.slug}
  end

  test "POST /fleets/:slug/events/:slug/sync-to-discord with OAuth bearer token" do
    fleet_event = create(:fleet_event, :open, fleet: @fleet, created_by: @admin)
    stub_discord_runnable

    assert_api_response :post, 200,
      path_params: {fleetSlug: @fleet.slug, slug: fleet_event.slug},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:write"])
  end

  test "POST /fleets/:slug/events/:slug/sync-to-discord returns 401 for OAuth token with wrong scope" do
    fleet_event = create(:fleet_event, :open, fleet: @fleet, created_by: @admin)

    assert_api_response :post, 401,
      path_params: {fleetSlug: @fleet.slug, slug: fleet_event.slug},
      headers: oauth_headers_for(@admin, scopes: ["public"])
  end

  test "POST /fleets/:slug/events/:slug/sync-to-discord returns 401 when not signed in" do
    fleet_event = create(:fleet_event, :open, fleet: @fleet, created_by: @admin)

    assert_api_response :post, 401, path_params: {fleetSlug: @fleet.slug, slug: fleet_event.slug}
  end
end
