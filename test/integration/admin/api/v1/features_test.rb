# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::FeaturesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/features" do
    get("Features list") do
      operationId "adminFeatures"
      tags "Features"
      produces "application/json"

      response(200, "successful") do
        schema ::Admin::V1::Schemas::FeaturesList
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path "/features/{id}" do
    parameter name: "id", in: :path, schema: {type: :string}, description: "Feature name", required: true

    get("Feature Detail") do
      operationId "adminFeature"
      tags "Features"
      produces "application/json"

      response(200, "successful") do
        schema ::Admin::V1::Schemas::Feature
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
    @user = create(:admin_user, resource_access: [:features])
  end

  # Flag lifecycle belongs to config/feature_flags.yml — see #4341. Creating a
  # flag here would leave it without a registry entry, and the next deploy's
  # `bin/feature-flags sync` would delete it along with every gate set on it.
  test "the admin API exposes no flag lifecycle actions" do
    actions = Admin::Api::V1::FeaturesController.action_methods

    assert_not_includes actions, "create"
    assert_not_includes actions, "destroy"

    routed = Rails.application.routes.routes.filter_map do |route|
      route.defaults[:action] if route.defaults[:controller] == "admin/api/v1/features"
    end

    assert_not_includes routed, "create"
    assert_not_includes routed, "destroy"
    assert_includes routed, "index"
    assert_includes routed, "enable"
  end

  # GET /features
  test "GET /features returns all features" do
    Flipper.enable("TestFeature")
    sign_in @user

    assert_api_response :get, 200 do
      assert_kind_of Array, parsed_body
      assert parsed_body.first["name"].present?
    end
  end

  test "GET /features returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /features returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403
  end

  # GET /features/:id
  test "GET /features/:id returns the feature" do
    Flipper.enable("TestFeature")
    sign_in @user

    assert_api_response :get, 200, path_params: {id: "TestFeature"}
  end

  test "GET /features/:id returns 404 for unknown feature" do
    sign_in @user

    assert_api_response :get, 404, path_params: {id: "NonExistentFeature"}
  end

  test "GET /features/:id returns 401 when not signed in" do
    Flipper.enable("TestFeature")

    assert_api_response :get, 401, path_params: {id: "TestFeature"}
  end

  test "GET /features/:id returns 403 for admin without access" do
    Flipper.enable("TestFeature")
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403, path_params: {id: "TestFeature"}
  end
end
