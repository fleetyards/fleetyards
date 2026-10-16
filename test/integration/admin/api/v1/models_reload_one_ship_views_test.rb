# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::ModelsReloadOneShipViewsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/models/{id}/reload-one-ship-views" do
    parameter name: "id", in: :path, description: "Model id", schema: {type: :string, format: :uuid}

    put("Sync Single Model Ship Views") do
      operationId "reloadOneModelShipViews"
      tags "Models"
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
    @user = create(:admin_user, resource_access: [:models])
  end

  test "PUT /models/:id/reload-one-ship-views enqueues the ship views import for the model" do
    model = create(:model)
    ::ScData::ShipViewsImportJob.expects(:perform_async).with(model.id)
    sign_in @user

    assert_api_response :put, 200, path_params: {id: model.id}, body: {}
  end

  test "PUT /models/:id/reload-one-ship-views returns 404 for missing id" do
    sign_in @user

    assert_api_response :put, 404, path_params: {id: SecureRandom.uuid}, body: {}
  end

  test "PUT /models/:id/reload-one-ship-views returns 401 when not signed in" do
    model = create(:model)

    assert_api_response :put, 401, path_params: {id: model.id}, body: {}
  end

  test "PUT /models/:id/reload-one-ship-views returns 403 for admin without access" do
    model = create(:model)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :put, 403, path_params: {id: model.id}, body: {}
  end
end
