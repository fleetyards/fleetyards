# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::FleetsConfirmRsiVerificationTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/fleets/{id}/rsi-verification" do
    parameter name: "id", in: :path, description: "Fleet id", schema: {type: :string, format: :uuid}

    post("Verify a fleet's RSI org without the token check") do
      operationId "confirmFleetRsiVerification"
      tags "Fleets"
      produces "application/json"

      response(200, "successful") do
        schema ::Admin::V1::Schemas::Fleet
      end

      response(400, "no RSI SID") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(409, "the SID changed while verifying") do
        schema ::Shared::V1::Schemas::StandardError
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
  end

  test "POST /fleets/:id/rsi-verification verifies the fleet" do
    sign_in @user

    assert_api_response :post, 200, path_params: {id: @fleet.id} do
      assert parsed_body["rsiVerified"]
    end

    assert @fleet.reload.rsi_verified?
  end

  test "POST /fleets/:id/rsi-verification returns 409 when the SID changes underneath it" do
    sign_in @user
    FleetRsiVerification.any_instance.stubs(:confirm!).returns(nil)

    assert_api_response :post, 409, path_params: {id: @fleet.id} do
      assert_equal "rsi_sid_changed", parsed_body["code"]
    end
  end

  test "POST /fleets/:id/rsi-verification returns 400 for a fleet without an SID" do
    fleet = create(:fleet, created_by: create(:user).id)
    sign_in @user

    assert_api_response :post, 400, path_params: {id: fleet.id}

    assert_not fleet.reload.rsi_verified?
  end

  test "POST /fleets/:id/rsi-verification returns 404 for missing id" do
    sign_in @user

    assert_api_response :post, 404, path_params: {id: SecureRandom.uuid}
  end

  test "POST /fleets/:id/rsi-verification returns 403 without access to fleets" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :post, 403, path_params: {id: @fleet.id}
  end

  test "POST /fleets/:id/rsi-verification returns 401 when not signed in" do
    assert_api_response :post, 401, path_params: {id: @fleet.id}
  end
end
