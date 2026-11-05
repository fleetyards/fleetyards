# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetSearchTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/search" do
    get("Search one fleet") do
      operationId "fleetSearch"
      tags "Search"
      produces "application/json"

      parameter name: "fleetSlug", in: :path, schema: {type: :string}, required: true
      parameter name: "q", in: :query, schema: {type: :string}, required: true

      response(200, "successful") do
        schema ::V1::Schemas::SearchResults
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    Flipper.enable("fleet_contracts")
    Flipper.enable("fleet_logistics")
    Flipper.enable("fleet_mission_builder")

    @officer = create(:user, username: "omniofficer")
    @member = create(:user)
    @outsider = create(:user)
    @fleet = create(:fleet, admins: [@officer], members: [@member])
    @depot = create(:fleet_inventory, fleet: @fleet)
  end

  def search(user, status = 200, &block)
    sign_in user

    assert_api_response :get, status, path_params: {fleetSlug: @fleet.slug}, params: {q: "omni"}, &block
  end

  def groups
    parsed_body["groups"].to_h { |group| [group["type"], group["items"].pluck("name")] }
  end

  test "GET /fleets/:slug/search finds members, events, contracts and inventory" do
    create(:fleet_event, fleet: @fleet, title: "Omni Raid")
    create(:fleet_contract, :published, fleet: @fleet, destination_fleet_inventory: @depot, title: "Omni Haul")
    create(:fleet_inventory_item, fleet_inventory: @depot, name: "Omni Ore")

    search(@member) do
      assert_equal(
        {
          "FleetMembership" => ["omniofficer"],
          "FleetEvent" => ["Omni Raid"],
          "FleetContract" => ["Omni Haul"],
          "FleetInventoryItem" => ["Omni Ore"]
        },
        groups
      )
    end
  end

  test "GET /fleets/:slug/search lists only accepted members" do
    %i[invited requested declined].each do |state|
      create(:fleet_membership, fleet: @fleet, user: create(:user, username: "omni#{state}"), aasm_state: state)
    end

    search(@officer) { assert_equal ["omniofficer"], groups["FleetMembership"] }
  end

  test "GET /fleets/:slug/search refuses someone outside the fleet" do
    create(:fleet_event, fleet: @fleet, title: "Omni Raid")

    search(@outsider, 404)
  end

  test "GET /fleets/:slug/search does not show a member a draft contract" do
    create(:fleet_contract, fleet: @fleet, destination_fleet_inventory: @depot, title: "Omni Draft")

    search(@member) { assert_nil groups["FleetContract"] }
  end

  test "GET /fleets/:slug/search shows a draft to someone who may publish it" do
    create(:fleet_contract, fleet: @fleet, destination_fleet_inventory: @depot, title: "Omni Draft")

    search(@officer) { assert_equal ["Omni Draft"], groups["FleetContract"] }
  end

  test "GET /fleets/:slug/search does not show a contract restricted to another squadron" do
    squadron = create(:fleet_squadron, fleet: @fleet)
    create(:fleet_contract, :published, fleet: @fleet, destination_fleet_inventory: @depot,
      visibility: :squadron_only, fleet_squadrons: [squadron], title: "Omni Secret")

    search(@member) { assert_nil groups["FleetContract"] }
  end

  test "GET /fleets/:slug/search leaves out an archived event" do
    create(:fleet_event, fleet: @fleet, title: "Omni Raid", archived_at: Time.current)

    search(@member) { assert_nil groups["FleetEvent"] }
  end

  test "GET /fleets/:slug/search does not show items from an officers-only inventory" do
    secret = create(:fleet_inventory, :officers_only, fleet: @fleet)
    create(:fleet_inventory_item, fleet_inventory: secret, name: "Omni Stash")

    search(@member) { assert_nil groups["FleetInventoryItem"] }
    search(@officer) { assert_equal ["Omni Stash"], groups["FleetInventoryItem"] }
  end

  test "GET /fleets/:slug/search leaves out a section whose feature is off" do
    Flipper.disable("fleet_contracts")
    create(:fleet_contract, :published, fleet: @fleet, destination_fleet_inventory: @depot, title: "Omni Haul")

    search(@officer) { assert_nil groups["FleetContract"] }
  end

  test "GET /fleets/:slug/search leaves out a section the fleet has not paid for" do
    Flipper.enable("fleet_subscriptions")
    create(:fleet_event, fleet: @fleet, title: "Omni Raid")

    search(@officer) do
      assert_nil groups["FleetEvent"]
      assert_equal ["omniofficer"], groups["FleetMembership"]
    end
  end
end
