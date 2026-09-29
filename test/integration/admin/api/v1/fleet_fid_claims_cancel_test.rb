# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::FleetFidClaimsCancelTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/fleet-fid-claims/{id}/cancel" do
    parameter name: "id", in: :path, description: "Claim id", schema: {type: :string, format: :uuid}

    put("Cancel an FID claim") do
      operationId "cancelFleetFidClaim"
      tags "Fleets"
      produces "application/json"

      response(200, "successful") do
        schema ::Admin::V1::Schemas::AdminFleetFidClaim
      end

      response(400, "bad request") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @user = create(:admin_user, resource_access: [:fleets])
    @claim = create(:fleet_fid_claim)
  end

  test "PUT /fleet-fid-claims/:id/cancel cancels the claim" do
    sign_in @user

    assert_api_response :put, 200, path_params: {id: @claim.id}

    assert @claim.reload.cancelled_by_admin?
    assert_equal "admin", response.parsed_body["cancelReason"]
  end

  test "PUT /fleet-fid-claims/:id/cancel refuses a claim that is no longer open" do
    @claim.cancel!(:withdrawn)
    sign_in @user

    assert_api_response :put, 400, path_params: {id: @claim.id}
  end

  test "PUT /fleet-fid-claims/:id/cancel returns 404 for missing id" do
    sign_in @user

    assert_api_response :put, 404, path_params: {id: SecureRandom.uuid}
  end

  test "PUT /fleet-fid-claims/:id/cancel returns 403 without access to fleets" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :put, 403, path_params: {id: @claim.id}
  end

  test "PUT /fleet-fid-claims/:id/cancel returns 401 when not signed in" do
    assert_api_response :put, 401, path_params: {id: @claim.id}
  end
end
