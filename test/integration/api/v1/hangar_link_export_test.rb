# frozen_string_literal: true

require "openapi_helper"

class Api::V1::HangarLinkExportTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/hangar/export/hangar-link" do
    get("Export your personal Hangar for hangar.link") do
      operationId "hangarLinkExport"
      tags "Hangar"
      produces "application/json"

      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/HangarQuery"
        },
        style: :deepObject,
        explode: true,
        required: false

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:read"]},
        {OpenId: ["hangar", "hangar:read"]}
      ]

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/VehicleExport"}
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  test "GET /hangar/export/hangar-link returns vehicle exports" do
    user = create(:user, wanted_vehicle_count: 2, vehicle_count: 3)
    sign_in user

    assert_api_response :get, 200 do
      assert_operator parsed_body.count, :>, 0
    end
  end

  test "GET /hangar/export/hangar-link emits the manufacturer-free slug" do
    user = create(:user)
    manufacturer = create(:manufacturer, code: "DRAK")
    model = create(:model, name: "Corsair", manufacturer:)
    model.update_columns(legacy_slug: "corsair", slug: "drak-corsair")
    create(:vehicle, user:, model:, wanted: false)

    sign_in user

    assert_api_response :get, 200 do
      assert_equal ["corsair"], parsed_body.map { |vehicle| vehicle["slug"] }
    end
  end

  test "GET /hangar/export/hangar-link returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /hangar/export/hangar-link with OAuth bearer token" do
    user = create(:user, wanted_vehicle_count: 2, vehicle_count: 3)

    assert_api_response :get, 200, headers: oauth_headers_for(user, scopes: ["hangar", "hangar:read"])
  end
end
