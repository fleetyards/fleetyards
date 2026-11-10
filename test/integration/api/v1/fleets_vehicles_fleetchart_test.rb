# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsVehiclesFleetchartTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/vehicles/fleetchart" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"

    get("Fleet ships for a fleetchart") do
      operationId "fleetVehiclesFleetchart"
      tags "Fleets"
      produces "application/json"

      parameter name: "q", in: :query,
        schema: ::V1::Schemas::Queries::FleetVehicleQuery,
        style: :deepObject,
        explode: true,
        required: false

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Fleets::Fleetchart::FleetFleetchart
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
    @admin = create(:user)
    @member = create(:user)
    @model = create(:model)
    @admin_ships = create_list(:vehicle, 2, user: @admin, model: @model)
    @member_ship = create(:vehicle, user: @member)
    @fleet = create(:fleet, :with_squadrons, admins: [@admin], members: [@member])
  end

  teardown do
    Sidekiq::Testing.fake!
  end

  test "lists every ship and sends each model once" do
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug}, params: {perPage: 1} do
      assert_equal [*@admin_ships, @member_ship].map(&:id).sort, parsed_body["items"].map { |item| item["id"] }.sort
      assert_equal [@model.id, @member_ship.model_id].sort, parsed_body["models"].map { |model| model["id"] }.sort
      assert_equal [@model.id], parsed_body["items"].select { |item| @admin_ships.map(&:id).include?(item["id"]) }.map { |item| item["modelId"] }.uniq
    end
  end

  test "applies the list's filters" do
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug}, params: {q: {memberIn: [@member.username]}} do
      assert_equal [@member_ship.id], parsed_body["items"].map { |item| item["id"] }
    end
  end

  test "names each ship's owner and ordinary squadron" do
    squadron = create(:fleet_squadron, fleet: @fleet)
    team = create(:fleet_squadron, fleet: @fleet, team: true)
    membership = @fleet.fleet_memberships.find_by!(user: @member)
    create(:fleet_squadron_membership, fleet_squadron: team, fleet_membership: membership)
    create(:fleet_squadron_membership, fleet_squadron: squadron, fleet_membership: membership)
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      items = parsed_body["items"].index_by { |item| item["id"] }

      assert_equal @member.username, items[@member_ship.id]["username"]
      assert_equal squadron.slug, items[@member_ship.id].dig("squadron", "slug")
      assert_nil items[@admin_ships.first.id]["squadron"]
    end
  end

  test "leaves out squadrons while the fleet has them switched off" do
    @fleet.update_column(:squadrons_enabled, false)
    squadron = create(:fleet_squadron, fleet: @fleet)
    create(:fleet_squadron_membership, fleet_squadron: squadron, fleet_membership: @fleet.fleet_memberships.find_by!(user: @member))
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert(parsed_body["items"].none? { |item| item.key?("squadron") })
    end
  end

  test "leaves out an owner who hides themselves" do
    @member.update!(hide_owner: true)
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      item = parsed_body["items"].find { |entry| entry["id"] == @member_ship.id }

      assert_not item.key?("username")
    end
  end

  test "refuses someone outside the fleet" do
    sign_in create(:user)

    assert_api_response :get, 404, path_params: {fleetSlug: @fleet.slug}
  end

  test "refuses an anonymous request" do
    assert_api_response :get, 401, path_params: {fleetSlug: @fleet.slug}
  end
end
