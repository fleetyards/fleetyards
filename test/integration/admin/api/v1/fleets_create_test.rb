# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::FleetsCreateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/fleets" do
    post("Create Fleet") do
      operationId "createFleet"
      tags "Fleets"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::Admin::V1::Schemas::Inputs::FleetInput

      response(200, "successful") do
        schema ::Admin::V1::Schemas::Fleet
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
  end

  test "POST /fleets creates a fleet" do
    sign_in @user

    assert_api_response :post, 200, body: {fid: "STARFLEET", name: "Starfleet"}
  end

  test "POST /fleets returns 401 when not signed in" do
    assert_api_response :post, 401, body: {fid: "x", name: "x"}
  end

  test "POST /fleets returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :post, 403, body: {fid: "x", name: "x"}
  end
end
