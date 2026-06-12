# frozen_string_literal: true

require_relative "../../../../openapi_helper"

class Admin::Api::V1::ModelsReloadOneTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/models/{id}/reload-one" do
    parameter name: "id", in: :path, description: "Model id", schema: {type: :string, format: :uuid}

    put("Reload Single Model") do
      operationId "reloadOneModel"
      tags "Models"
      produces "application/json"

      response(200, "successful") do
        schema type: :object, properties: {message: {type: :string}}, required: [:message]
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
    @user = create(:admin_user, resource_access: [:models])
  end

  test "PUT /models/:id/reload-one enqueues the loaders" do
    model = create(:model)
    Loaders::ModelJob.stubs(:perform_async)
    Loaders::ScData::ModelJob.stubs(:perform_async)
    sign_in @user

    assert_api_response :put, 200, path_params: {id: model.id}, body: {}
  end

  test "PUT /models/:id/reload-one returns 404 for missing id" do
    sign_in @user

    assert_api_response :put, 404, path_params: {id: SecureRandom.uuid}, body: {}
  end

  test "PUT /models/:id/reload-one returns 401 when not signed in" do
    model = create(:model)

    assert_api_response :put, 401, path_params: {id: model.id}, body: {}
  end

  test "PUT /models/:id/reload-one returns 403 for admin without access" do
    model = create(:model)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :put, 403, path_params: {id: model.id}, body: {}
  end
end
