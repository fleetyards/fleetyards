# frozen_string_literal: true

require_relative "../../../../openapi_helper"

class Admin::Api::V1::FleetsDestroyTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/fleets/{id}" do
    parameter name: "id", in: :path, description: "Fleet id", schema: {type: :string, format: :uuid}

    delete("Destroy Fleet") do
      operationId "destroyFleet"
      tags "Fleets"
      produces "application/json"

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

  test "DELETE /fleets/:id destroys the fleet" do
    fleet = create(:fleet)
    sign_in @user

    assert_api_response :delete, 200, path_params: {id: fleet.id}
  end

  test "DELETE /fleets/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :delete, 404, path_params: {id: SecureRandom.uuid}
  end

  test "DELETE /fleets/:id returns 401 when not signed in" do
    fleet = create(:fleet)

    assert_api_response :delete, 401, path_params: {id: fleet.id}
  end

  test "DELETE /fleets/:id returns 403 for admin without access" do
    fleet = create(:fleet)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :delete, 403, path_params: {id: fleet.id}
  end
end
