# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::FleetsUpdateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/fleets/{id}" do
    parameter name: "id", in: :path, description: "Fleet id", schema: {type: :string, format: :uuid}

    put("Update Fleet") do
      operationId "updateFleet"
      tags "Fleets"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/FleetInput"}

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Fleet"
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"
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

  test "PUT /fleets/:id updates the fleet" do
    fleet = create(:fleet)
    sign_in @user

    assert_api_response :put, 200, path_params: {id: fleet.id}, body: {name: "Updated Fleet"}
  end

  test "PUT /fleets/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :put, 404, path_params: {id: SecureRandom.uuid}, body: {name: "x"}
  end

  test "PUT /fleets/:id returns 401 when not signed in" do
    fleet = create(:fleet)

    assert_api_response :put, 401, path_params: {id: fleet.id}, body: {name: "x"}
  end

  test "PUT /fleets/:id returns 403 for admin without access" do
    fleet = create(:fleet)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :put, 403, path_params: {id: fleet.id}, body: {name: "x"}
  end
end
