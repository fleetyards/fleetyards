# frozen_string_literal: true

require_relative "../../../../openapi_helper"

class Admin::Api::V1::FleetsOptionsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/fleets/options" do
    get("Fleet Options") do
      operationId "fleetOptions"
      tags "Fleets"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "q", in: :query, schema: {type: :object, "$ref": "#/components/schemas/FleetQuery"}, required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetOptions"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  setup do
    @user = create(:admin_user, resource_access: [:fleets])
  end

  test "GET /fleets/options returns options" do
    create_list(:fleet, 3)
    sign_in @user

    assert_api_response :get, 200
  end

  test "GET /fleets/options returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /fleets/options returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403
  end
end
