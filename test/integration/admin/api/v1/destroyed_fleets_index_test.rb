# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::DestroyedFleetsIndexTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/destroyed-fleets" do
    get("Destroyed Fleets list") do
      operationId "destroyedFleets"
      tags "Fleets"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "source", in: :query, description: "discarded (soft-deleted) or purged (hard-deleted)", schema: {type: :string, enum: %w[discarded purged]}, required: false
      parameter name: "q", in: :query, schema: {type: :object, "$ref": "#/components/schemas/DestroyedFleetQuery"}, required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/DestroyedFleets"
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
    @creator = create(:user)
  end

  test "GET /destroyed-fleets lists discarded fleets" do
    fleet = create(:fleet, created_by: @creator.id)
    fleet.discard
    sign_in @user

    assert_api_response :get, 200, params: {source: "discarded"} do
      assert_equal 1, parsed_body["items"].size
      assert_equal "discarded", parsed_body["items"].first["source"]
    end
  end

  test "GET /destroyed-fleets lists purged fleets from paper trail" do
    fleet = create(:fleet, created_by: @creator.id)
    fleet.destroy
    sign_in @user

    assert_api_response :get, 200, params: {source: "purged"} do
      assert_equal "purged", parsed_body["items"].first["source"]
    end
  end

  test "GET /destroyed-fleets returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /destroyed-fleets returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403
  end
end
