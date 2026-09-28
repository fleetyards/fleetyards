# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::FleetsRevokeRsiVerificationTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/fleets/{id}/rsi-verification" do
    parameter name: "id", in: :path, description: "Fleet id", schema: {type: :string, format: :uuid}

    delete("Revoke a fleet's RSI verification") do
      operationId "revokeFleetRsiVerification"
      tags "Fleets"
      produces "application/json"

      response(200, "successful") do
        schema ::Admin::V1::Schemas::Fleet
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
    @fleet = create(:fleet, created_by: create(:user).id, rsi_sid: "TEST")
    @fleet.update_columns(rsi_verified_at: Time.current, rsi_verified_sid: "TEST", rsi_verification_status: :verified) # rubocop:disable Rails/SkipsModelValidations
  end

  test "DELETE /fleets/:id/rsi-verification unverifies the fleet" do
    sign_in @user

    assert_api_response :delete, 200, path_params: {id: @fleet.id}

    assert_not @fleet.reload.rsi_verified?
    assert_equal "TEST", @fleet.rsi_sid
  end

  test "DELETE /fleets/:id/rsi-verification returns 404 for missing id" do
    sign_in @user

    assert_api_response :delete, 404, path_params: {id: SecureRandom.uuid}
  end

  test "DELETE /fleets/:id/rsi-verification returns 403 without access to fleets" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :delete, 403, path_params: {id: @fleet.id}
  end

  test "DELETE /fleets/:id/rsi-verification returns 401 when not signed in" do
    assert_api_response :delete, 401, path_params: {id: @fleet.id}
  end
end
