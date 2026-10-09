# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsActivityIndexTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/activity" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}

    get("Fleet Activity") do
      operationId "fleetActivity"
      tags "Fleets"
      produces "application/json"

      parameter name: :category, in: :query, required: false,
        schema: {"$ref": "#/components/schemas/FleetActivityCategoryEnum"}
      parameter name: :exclude, in: :query, required: false,
        schema: {"$ref": "#/components/schemas/FleetActivityCategoryEnum"}
      parameter name: :limit, in: :query, required: false, schema: {type: :integer, minimum: 1, maximum: 50}

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Fleets::Activity::FleetActivitiesList
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    Flipper.enable("fleet_mission_builder")
    Flipper.enable("fleet_contracts")
    Flipper.enable("fleet_logistics")
    travel_to Time.zone.parse("2026-05-13 20:00:00 UTC")

    @admin = create(:user)
    @member = create(:user)
    @fleet = create(:fleet, admins: [@admin], members: [@member])
    @fleet.fleet_memberships.find_by(user: @member).update!(accepted_at: 2.days.ago)
  end

  teardown do
    travel_back
  end

  def kinds_and_titles
    parsed_body["items"].map { |entry| [entry["kind"], entry.dig("subject", "title")] }
  end

  test "GET /fleets/:slug/activity merges the fleet's recent records, newest first" do
    create(:fleet_event, :open, fleet: @fleet, created_by: @admin, title: "Mining op",
      starts_at: 3.days.from_now, published_at: 1.day.ago)
    create(:fleet_contract, :published, fleet: @fleet, created_by: @admin, title: "Haul quantanium",
      published_at: 3.hours.ago)
    inventory = create(:fleet_inventory, fleet: @fleet, name: "Main store")
    create(:fleet_inventory_item, fleet_inventory: inventory, name: "Laranite", added_by_user: @member,
      created_at: 1.hour.ago)

    sign_in @member
    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      kinds = kinds_and_titles
      assert_equal ["inventory_item_deposited", "Laranite"], kinds[0]
      assert_equal ["contract_published", "Haul quantanium"], kinds[1]
      assert_equal ["event_published", "Mining op"], kinds[2]
      refute parsed_body["items"][2]["involvesViewer"]
      assert_includes kinds.map(&:first), "member_joined"

      item = parsed_body["items"].first
      assert item["involvesViewer"]
      assert_equal "inventory", item["category"]
      assert_equal "Main store", item.dig("inventory", "name")
    end
  end

  # Each source answers as its own list would, so the feed never shows a member
  # what the events board or the logistics page would keep from them.
  test "GET /fleets/:slug/activity keeps out what the reader may not see" do
    squadron = create(:fleet_squadron, fleet: @fleet)
    create(:fleet_event, :open, fleet: @fleet, created_by: @admin, title: "Squadron only",
      starts_at: 3.days.from_now, visibility: "squadron", fleet_squadrons: [squadron])
    create(:fleet_event, fleet: @fleet, created_by: @admin, title: "Still a draft", starts_at: 3.days.from_now)
    hidden = create(:fleet_inventory, :officers_only, fleet: @fleet)
    create(:fleet_inventory_item, fleet_inventory: hidden, name: "Officer stash")

    sign_in @member
    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      titles = kinds_and_titles.map(&:last)
      refute_includes titles, "Squadron only"
      refute_includes titles, "Still a draft"
      refute_includes titles, "Officer stash"
    end

    sign_in @admin
    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      titles = kinds_and_titles.map(&:last)
      assert_includes titles, "Squadron only"
      assert_includes titles, "Officer stash"
      refute_includes titles, "Still a draft"
    end
  end

  test "GET /fleets/:slug/activity marks an event the reader published as theirs" do
    create(:fleet_event, :open, fleet: @fleet, created_by: @member, title: "My op",
      starts_at: 3.days.from_now, published_at: 1.day.ago)

    sign_in @member
    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug}, params: {category: "events"} do
      assert parsed_body["items"].first["involvesViewer"]
    end
  end

  # The items a transfer moved arrive with it, so they are told once, by the
  # transfer, rather than once each.
  test "GET /fleets/:slug/activity tells a completed transfer once" do
    inventory = create(:fleet_inventory, fleet: @fleet, name: "Main store")
    transfer = create(:inventory_transfer, :from_fleet, :to_inventory, :completed,
      source_fleet_inventory: inventory, initiated_by: @member, completed_at: 1.hour.ago)
    create(:fleet_inventory_item, fleet_inventory: inventory, inventory_transfer: transfer)

    sign_in @admin
    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug}, params: {category: "inventory"} do
      assert_equal ["inventory_transfer_completed"], parsed_body["items"].map { |entry| entry["kind"] }
      entry = parsed_body["items"].first
      assert_equal @member.username, entry.dig("actor", "username")
      refute entry["involvesViewer"]
    end
  end

  test "GET /fleets/:slug/activity leaves out a module whose feature is off" do
    Flipper.disable("fleet_contracts")
    create(:fleet_contract, :published, fleet: @fleet, created_by: @admin, title: "Haul quantanium")

    sign_in @member
    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      refute_includes parsed_body["items"].map { |entry| entry["category"] }, "contracts"
    end
  end

  test "GET /fleets/:slug/activity leaves out premium modules for an unsubscribed fleet" do
    Flipper.enable("fleet_subscriptions")
    create(:fleet_event, :open, fleet: @fleet, created_by: @admin, title: "Mining op",
      starts_at: 3.days.from_now)

    sign_in @member
    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal ["members"], parsed_body["items"].map { |entry| entry["category"] }.uniq
    end
  ensure
    Flipper.disable("fleet_subscriptions")
  end

  test "GET /fleets/:slug/activity narrows to one category and a page size" do
    create(:fleet_event, :open, fleet: @fleet, created_by: @admin, title: "Older",
      starts_at: 3.days.from_now, published_at: 2.days.ago)
    create(:fleet_event, :open, fleet: @fleet, created_by: @admin, title: "Newer",
      starts_at: 3.days.from_now, published_at: 1.day.ago)

    sign_in @member
    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug}, params: {category: "events", limit: 1} do
      assert_equal [["event_published", "Newer"]], kinds_and_titles
    end

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug}, params: {category: "events"} do
      assert_equal [["event_published", "Newer"], ["event_published", "Older"]], kinds_and_titles
    end
  end

  # The dashboard shows who joined in a panel of its own, so its feed leaves
  # them out rather than telling each one twice.
  test "GET /fleets/:slug/activity leaves out an excluded category" do
    create(:fleet_event, :open, fleet: @fleet, created_by: @admin, title: "Mining op",
      starts_at: 3.days.from_now, published_at: 1.day.ago)

    sign_in @member
    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug}, params: {exclude: "members"} do
      assert_equal ["events"], parsed_body["items"].map { |entry| entry["category"] }.uniq
    end
  end

  test "GET /fleets/:slug/activity is refused to somebody outside the fleet" do
    sign_in create(:user)

    get "/api/v1/fleets/#{@fleet.slug}/activity"

    assert_includes [403, 404], response.status
  end

  test "GET /fleets/:slug/activity with OAuth bearer token" do
    assert_api_response :get, 200,
      path_params: {fleetSlug: @fleet.slug},
      headers: oauth_headers_for(@member, scopes: ["fleet", "fleet:read"])
  end

  test "GET /fleets/:slug/activity returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: {fleetSlug: @fleet.slug}
  end
end
