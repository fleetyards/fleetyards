# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::ComponentsSyncViewsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/components/{id}/sync-views" do
    parameter name: "id", in: :path, description: "Component id", schema: {type: :string, format: :uuid}

    put("Sync Component Views") do
      operationId "syncComponentViews"
      tags "Components"
      produces "application/json"

      response(200, "successful") do
        schema ::Admin::V1::Schemas::MessageResponse
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
    @user = create(:admin_user, resource_access: [:components])
  end

  test "PUT /components/:id/sync-views enqueues the item views import for it" do
    component = create(:component)
    ::ScData::ItemViewsImportJob.expects(:perform_async).with("Component", component.id)
    sign_in @user

    assert_api_response :put, 200, path_params: {id: component.id}, body: {}
  end

  test "PUT /components/:id/sync-views returns 404 for missing id" do
    sign_in @user

    assert_api_response :put, 404, path_params: {id: SecureRandom.uuid}, body: {}
  end

  test "PUT /components/:id/sync-views returns 401 when not signed in" do
    component = create(:component)

    assert_api_response :put, 401, path_params: {id: component.id}, body: {}
  end

  test "PUT /components/:id/sync-views returns 403 for admin without access" do
    component = create(:component)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :put, 403, path_params: {id: component.id}, body: {}
  end
end
