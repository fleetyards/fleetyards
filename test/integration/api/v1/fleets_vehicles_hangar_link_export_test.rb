# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsVehiclesHangarLinkExportTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/vehicles/export/hangar-link" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"

    get("Export a Fleet for hangar.link") do
      operationId "fleetVehiclesHangarLinkExport"
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
        schema ::V1::Schemas::Fleets::FleetVehicleExportsList
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

  test "GET /fleets/:slug/vehicles/export/hangar-link returns vehicle exports" do
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal 3, parsed_body.count
    end
  end

  test "GET /fleets/:slug/vehicles/export/hangar-link emits the manufacturer-free slug" do
    user = create(:user)
    manufacturer = create(:manufacturer, code: "DRAK")
    model = create(:model, name: "Corsair", manufacturer:)
    model.update_columns(legacy_slug: "corsair", slug: "drak-corsair")
    create(:vehicle, user:, model:, wanted: false)

    fleet = create(:fleet, admins: [user])

    sign_in user

    assert_api_response :get, 200, path_params: {fleetSlug: fleet.slug} do
      assert_equal ["corsair"], parsed_body.map { |vehicle| vehicle["slug"] }
    end
  end

  test "GET /fleets/:slug/vehicles/export/hangar-link is accessible to a non-admin member" do
    sign_in @member

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal 3, parsed_body.count
    end
  end

  test "GET /fleets/:slug/vehicles/export/hangar-link returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: {fleetSlug: @fleet.slug}
  end

  test "GET /fleets/:slug/vehicles/export/hangar-link with OAuth bearer token" do
    assert_api_response :get, 200,
      path_params: {fleetSlug: @fleet.slug},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:read"])
  end
end
