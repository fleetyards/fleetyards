# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::DestroyedFleetsRestoreTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/destroyed-fleets/{id}/restore" do
    parameter name: "id", in: :path, description: "Fleet id", schema: {type: :string, format: :uuid}

    post("Restore a destroyed fleet") do
      operationId "restoreDestroyedFleet"
      tags "Fleets"
      produces "application/json"

      parameter name: "source", in: :query, description: "discarded (soft-deleted) or purged (hard-deleted)", schema: {type: :string, enum: %w[discarded purged]}, required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Fleet"
      end

      response(422, "unprocessable entity") do
        schema "$ref": "#/components/schemas/StandardError"
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
    @creator = create(:user)
  end

  test "POST /restore undiscards a discarded fleet" do
    fleet = create(:fleet, created_by: @creator.id)
    fleet.discard
    sign_in @user

    assert_api_response :post, 200, path_params: {id: fleet.id}, params: {source: "discarded"}
    assert fleet.reload.kept?
  end

  test "POST /restore rebuilds a purged fleet from paper trail" do
    fleet = create(:fleet, created_by: @creator.id)
    fleet_id = fleet.id
    fleet.destroy
    sign_in @user

    assert_api_response :post, 200, path_params: {id: fleet_id}, params: {source: "purged"}
    assert Fleet.exists?(fleet_id)
  end

  test "POST /restore returns 422 when the fleet still exists" do
    fleet = create(:fleet, created_by: @creator.id)
    sign_in @user

    assert_api_response :post, 422, path_params: {id: fleet.id}, params: {source: "purged"}
  end

  test "POST /restore returns 422 when another kept fleet already uses the fid" do
    fleet = create(:fleet, created_by: @creator.id, fid: "TAKEN")
    fleet.discard
    create(:fleet, created_by: @creator.id, fid: "TAKEN")
    sign_in @user

    assert_api_response :post, 422, path_params: {id: fleet.id}, params: {source: "discarded"}
  end

  test "POST /restore returns 404 for an unknown destroyed fleet" do
    sign_in @user

    assert_api_response :post, 404, path_params: {id: SecureRandom.uuid}, params: {source: "purged"}
  end

  test "POST /restore returns 401 when not signed in" do
    fleet = create(:fleet, created_by: @creator.id)
    fleet.discard

    assert_api_response :post, 401, path_params: {id: fleet.id}, params: {source: "discarded"}
  end

  test "POST /restore returns 403 for admin without access" do
    fleet = create(:fleet, created_by: @creator.id)
    fleet.discard
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :post, 403, path_params: {id: fleet.id}, params: {source: "discarded"}
  end
end
