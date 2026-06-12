# frozen_string_literal: true

require_relative "../../../../openapi_helper"

class Admin::Api::V1::FleetsIndexTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/fleets" do
    get("Fleets list") do
      operationId "fleets"
      tags "Fleets"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter "$ref": "#/components/parameters/SortingParameter"
      parameter name: "q", in: :query, schema: {type: :object, "$ref": "#/components/schemas/FleetQuery"}, required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Fleets"
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

  test "GET /fleets lists fleets" do
    create_list(:fleet, 3)
    sign_in @user

    assert_api_response :get, 200
  end

  test "GET /fleets returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /fleets returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403
  end
end
