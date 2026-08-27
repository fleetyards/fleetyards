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

      request_body required: true, schema: ::Admin::V1::Schemas::Inputs::FleetInput

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
  end

  test "PUT /fleets/:id updates the fleet" do
    fleet = create(:fleet)
    sign_in @user

    assert_api_response :put, 200, path_params: {id: fleet.id}, body: {name: "Updated Fleet"}
  end

  # Clearing sends a null -- that is what the file input emits -- so the request
  # schema has to accept one, or the admin UI cannot remove a picture at all.
  test "PUT /fleets/:id clears the logo" do
    fleet = create(:fleet)
    fleet.logo.attach(
      io: File.open(Rails.root.join("test/fixtures/files/test.png")),
      filename: "test.png",
      content_type: "image/png"
    )
    sign_in @user

    assert_api_response :put, 200, path_params: {id: fleet.id}, body: {logo: nil}

    assert_not_predicate fleet.reload.logo, :attached?
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
