# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::FleetFidClaimsIndexTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/fleet-fid-claims" do
    get("Open FID claims") do
      operationId "fleetFidClaims"
      tags "Fleets"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: FleetFidClaim.default_per_page}, required: false

      response(200, "successful") do
        schema ::Admin::V1::Schemas::AdminFleetFidClaims
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
    create(:fleet_fid_claim, claimant: create(:fleet, :rsi_verified, rsi_sid: "DONE"), state: :completed)
  end

  test "GET /fleet-fid-claims lists the open claims" do
    sign_in @user

    assert_api_response :get, 200

    assert_equal [@claim.id], response.parsed_body["items"].pluck("id")
    assert_equal @claim.holder.fid, response.parsed_body["items"].first["holderFid"]
  end

  test "GET /fleet-fid-claims returns 403 without access to fleets" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403
  end

  test "GET /fleet-fid-claims returns 401 when not signed in" do
    assert_api_response :get, 401
  end
end
