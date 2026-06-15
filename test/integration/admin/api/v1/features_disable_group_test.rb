# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::FeaturesDisableGroupTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/features/{id}/disable-group" do
    parameter name: "id", in: :path, schema: {type: :string}, description: "Feature name", required: true

    put("Disable Feature for Group") do
      operationId "disableAdminFeatureGroup"
      tags "Features"
      consumes "application/json"
      produces "application/json"

      request_body schema: {"$ref": "#/components/schemas/FeatureGroupInput"}

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Feature"
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
    @user = create(:admin_user, resource_access: [:features])
    Flipper.add("TestFeature")
    Flipper.feature("TestFeature").enable_group(:testers)
  end

  test "PUT /features/:id/disable-group disables for the group" do
    sign_in @user

    assert_api_response :put, 200, path_params: {id: "TestFeature"}, body: {group: "testers"}
  end

  test "PUT /features/:id/disable-group returns 404 for unknown feature" do
    sign_in @user

    assert_api_response :put, 404, path_params: {id: "NonExistentFeature"}, body: {group: "testers"}
  end

  test "PUT /features/:id/disable-group returns 401 when not signed in" do
    assert_api_response :put, 401, path_params: {id: "TestFeature"}, body: {group: "testers"}
  end

  test "PUT /features/:id/disable-group returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :put, 403, path_params: {id: "TestFeature"}, body: {group: "testers"}
  end
end
