# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsVehiclesIndexTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/vehicles" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"

    get("Fleet Vehicles List") do
      operationId "fleetVehicles"
      tags "Fleets"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: FleetVehicle.default_per_page}, required: false
      parameter name: "q", in: :query,
        schema: ::V1::Schemas::Queries::FleetVehicleQuery,
        style: :deepObject,
        explode: true,
        required: false
      parameter name: "grouped", in: :query, schema: {type: :boolean}, required: false
      parameter name: "cacheId", in: :query, schema: {type: :string}, required: false

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Fleets::FleetVehicles
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    Sidekiq::Testing.inline!
    @admin = create(:user, vehicle_count: 2)
    @member = create(:user, vehicle_count: 1)
    @fleet = create(:fleet, admins: [@admin], members: [@member])
  end

  teardown do
    Sidekiq::Testing.fake!
  end

  test "GET /fleets/:slug/vehicles lists fleet vehicles" do
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal 3, parsed_body["items"].count
    end
  end

  test "GET /fleets/:slug/vehicles filters by modelNameCont" do
    sign_in @admin

    assert_api_response :get, 200,
      path_params: {fleetSlug: @fleet.slug},
      params: {q: {"modelNameCont" => @fleet.models.first.name}} do
      assert_equal 1, parsed_body["items"].count
    end
  end

  test "GET /fleets/:slug/vehicles honours perPage" do
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug}, params: {perPage: 1} do
      assert_equal 1, parsed_body["items"].count
    end
  end

  test "GET /fleets/:slug/vehicles honours grouped flag" do
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug}, params: {grouped: true} do
      assert_equal 3, parsed_body["items"].count
    end
  end

  def fleet_with_ships(lengths)
    owner = create(:user)
    lengths.each_with_index do |length, index|
      manufacturer = create(:manufacturer, name: "Maker #{("A".ord + index).chr}")
      create(:vehicle, user: owner, model: create(:model, length:, manufacturer:))
    end

    [owner, create(:fleet, admins: [owner])]
  end

  test "GET /fleets/:slug/vehicles sorts by the ship's own figures" do
    owner, fleet = fleet_with_ships([20, 80, 50])
    sign_in owner

    assert_api_response :get, 200,
      path_params: {fleetSlug: fleet.slug},
      params: {q: {s: "modelLength desc"}} do
      assert_equal [80, 50, 20], parsed_body["items"].map { |item| item.dig("model", "metrics", "length") }
    end
  end

  test "GET /fleets/:slug/vehicles sorts by manufacturer" do
    owner, fleet = fleet_with_ships([20, 80, 50])
    sign_in owner

    assert_api_response :get, 200,
      path_params: {fleetSlug: fleet.slug},
      params: {q: {s: "modelManufacturerName desc"}} do
      assert_equal ["Maker C", "Maker B", "Maker A"],
        parsed_body["items"].map { |item| item.dig("model", "manufacturer", "name") }
    end
  end

  test "GET /fleets/:slug/vehicles sorts a grouped list by the ship" do
    owner, fleet = fleet_with_ships([20, 80, 50])
    sign_in owner

    assert_api_response :get, 200,
      path_params: {fleetSlug: fleet.slug},
      params: {grouped: true, q: {s: "modelManufacturerName desc"}} do
      assert_equal ["Maker C", "Maker B", "Maker A"],
        parsed_body["items"].map { |item| item.dig("manufacturer", "name") }
    end
  end

  # A grouped list holds ships, which have no date a vehicle was added on.
  test "GET /fleets/:slug/vehicles falls back to the name for a grouped list sorted by date" do
    owner, fleet = fleet_with_ships([20, 80])
    sign_in owner

    assert_api_response :get, 200,
      path_params: {fleetSlug: fleet.slug},
      params: {grouped: true, q: {s: "createdAt desc"}} do
      names = parsed_body["items"].map { |item| item["name"] }
      assert_equal names.sort, names
    end
  end

  def fleet_with_holdings(holdings)
    owners = holdings.keys.map { |username| create(:user, username:) }
    models = holdings.values.flat_map(&:keys).uniq.index_with { |name| create(:model, name:) }

    holdings.each_with_index do |(_username, counts), index|
      counts.each do |name, count|
        create_list(:vehicle, count, user: owners[index], model: models[name])
      end
    end

    [owners.first, create(:fleet, admins: owners)]
  end

  test "GET /fleets/:slug/vehicles sorts a grouped list by how many of each ship the fleet holds" do
    owner, fleet = fleet_with_holdings({"pilot" => {"Alpha" => 1, "Bravo" => 3, "Charlie" => 2}})
    sign_in owner

    assert_api_response :get, 200,
      path_params: {fleetSlug: fleet.slug},
      params: {grouped: true, q: {s: "vehiclesCount desc"}} do
      assert_equal %w[Bravo Charlie Alpha], parsed_body["items"].map { |item| item["name"] }
    end

    assert_api_response :get, 200,
      path_params: {fleetSlug: fleet.slug},
      params: {grouped: true, q: {s: "vehiclesCount asc"}} do
      assert_equal %w[Alpha Charlie Bravo], parsed_body["items"].map { |item| item["name"] }
    end
  end

  test "GET /fleets/:slug/vehicles breaks a tie in the count by the name" do
    owner, fleet = fleet_with_holdings({"pilot" => {"Charlie" => 2, "Alpha" => 2, "Bravo" => 1}})
    sign_in owner

    assert_api_response :get, 200,
      path_params: {fleetSlug: fleet.slug},
      params: {grouped: true, q: {s: "vehiclesCount desc"}} do
      assert_equal %w[Alpha Charlie Bravo], parsed_body["items"].map { |item| item["name"] }
    end
  end

  test "GET /fleets/:slug/vehicles keeps the count behind a sort that comes first" do
    owner, fleet = fleet_with_holdings({"pilot" => {"Alpha" => 1, "Bravo" => 3, "Charlie" => 2}})
    sign_in owner

    assert_api_response :get, 200,
      path_params: {fleetSlug: fleet.slug},
      params: {grouped: true, q: {sorts: ["modelName asc", "vehiclesCount desc"]}} do
      assert_equal %w[Alpha Bravo Charlie], parsed_body["items"].map { |item| item["name"] }
    end
  end

  test "GET /fleets/:slug/vehicles puts the count before a sort that comes after it" do
    owner, fleet = fleet_with_holdings({"pilot" => {"Charlie" => 2, "Alpha" => 2, "Bravo" => 1}})
    sign_in owner

    assert_api_response :get, 200,
      path_params: {fleetSlug: fleet.slug},
      params: {grouped: true, q: {sorts: ["vehiclesCount desc", "modelName desc"]}} do
      assert_equal %w[Charlie Alpha Bravo], parsed_body["items"].map { |item| item["name"] }
    end
  end

  test "GET /fleets/:slug/vehicles counts only the vehicles the filters admit" do
    owner, fleet = fleet_with_holdings({
      "pilot" => {"Alpha" => 1, "Bravo" => 2},
      "gunner" => {"Alpha" => 3}
    })
    sign_in owner

    assert_api_response :get, 200,
      path_params: {fleetSlug: fleet.slug},
      params: {grouped: true, q: {s: "vehiclesCount desc"}} do
      assert_equal %w[Alpha Bravo], parsed_body["items"].map { |item| item["name"] }
    end

    assert_api_response :get, 200,
      path_params: {fleetSlug: fleet.slug},
      params: {grouped: true, q: {s: "vehiclesCount desc", memberIn: ["pilot"]}} do
      assert_equal %w[Bravo Alpha], parsed_body["items"].map { |item| item["name"] }
    end
  end

  # Each row of an ungrouped list is one vehicle, so there is nothing to count.
  test "GET /fleets/:slug/vehicles falls back to the name for an ungrouped list sorted by count" do
    owner, fleet = fleet_with_holdings({"pilot" => {"Charlie" => 1, "Alpha" => 1, "Bravo" => 2}})
    sign_in owner

    assert_api_response :get, 200,
      path_params: {fleetSlug: fleet.slug},
      params: {q: {s: "vehiclesCount desc"}} do
      assert_equal %w[Alpha Bravo Bravo Charlie], parsed_body["items"].map { |item| item.dig("model", "name") }
    end
  end

  test "GET /fleets/:slug/vehicles works for members" do
    sign_in @member

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal 3, parsed_body["items"].count
    end
  end

  test "GET /fleets/:slug/vehicles returns 404 for unknown fleet" do
    sign_in @admin

    assert_api_response :get, 404, path_params: {fleetSlug: "unknown-fleet"}
  end

  test "GET /fleets/:slug/vehicles returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: {fleetSlug: @fleet.slug}
  end

  test "GET /fleets/:slug/vehicles with OAuth bearer token" do
    assert_api_response :get, 200,
      path_params: {fleetSlug: @fleet.slug},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:read"])
  end
end
