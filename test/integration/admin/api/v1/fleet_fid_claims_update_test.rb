# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::FleetFidClaimsUpdateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/fleet-fid-claims/{id}" do
    parameter name: "id", in: :path, description: "Claim id", schema: {type: :string, format: :uuid}

    patch("Shorten an FID claim's grace period") do
      operationId "updateFleetFidClaim"
      tags "Fleets"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::Admin::V1::Schemas::Inputs::FleetFidClaimUpdateInput

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

  test "PATCH /fleet-fid-claims/:id moves the end of the grace period forward" do
    sign_in @user
    ends_at = 2.days.from_now.change(usec: 0)

    assert_api_response :patch, 200, path_params: {id: @claim.id}, body: {endsAt: ends_at.iso8601}

    assert_equal ends_at, @claim.reload.ends_at
    assert @claim.open?
  end

  test "PATCH /fleet-fid-claims/:id to now completes the claim" do
    sign_in @user

    assert_api_response :patch, 200, path_params: {id: @claim.id}, body: {endsAt: Time.current.iso8601}

    assert_equal "completed", response.parsed_body["state"]
    assert_equal @claim.fid, @claim.claimant.reload.fid
    assert_equal @claim.fid, response.parsed_body["claimantFid"]
  end

  test "PATCH /fleet-fid-claims/:id to now refuses a claimant that is no longer verified" do
    @claim.claimant.update_columns(rsi_verified_at: nil, rsi_verified_sid: nil) # rubocop:disable Rails/SkipsModelValidations
    sign_in @user

    assert_api_response :patch, 400, path_params: {id: @claim.id}, body: {endsAt: Time.current.iso8601}

    assert_equal "validation_error.fleet_fid_claim.complete", response.parsed_body["code"]
    assert @claim.reload.cancelled_by_claimant_unverified?
  end

  test "PATCH /fleet-fid-claims/:id cannot extend the grace period" do
    sign_in @user

    assert_api_response :patch, 400, path_params: {id: @claim.id}, body: {endsAt: 30.days.from_now.iso8601}
  end

  test "PATCH /fleet-fid-claims/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :patch, 404, path_params: {id: SecureRandom.uuid}, body: {endsAt: Time.current.iso8601}
  end

  test "PATCH /fleet-fid-claims/:id returns 403 without access to fleets" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :patch, 403, path_params: {id: @claim.id}, body: {endsAt: Time.current.iso8601}
  end

  test "PATCH /fleet-fid-claims/:id returns 401 when not signed in" do
    assert_api_response :patch, 401, path_params: {id: @claim.id}, body: {endsAt: Time.current.iso8601}
  end
end
