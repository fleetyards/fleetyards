# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::ModelsUseRsiImageTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/models/{id}/use-rsi-image" do
    parameter name: "id", in: :path, description: "Model id", schema: {type: :string, format: :uuid}

    put("Use RSI Image") do
      operationId "useRsiImage"
      tags "Models"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelExtended"
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

  def model_with_rsi_store_image
    model = create(:model)
    model.rsi_store_image.attach(
      io: file_fixture("test.png").open,
      filename: "test.png",
      content_type: "image/png"
    )
    model
  end

  test "PUT /models/:id/use-rsi-image swaps in the RSI store image" do
    model = model_with_rsi_store_image
    sign_in @user

    assert_api_response :put, 200, path_params: {id: model.id}, body: {}
  end

  test "PUT /models/:id/use-rsi-image returns 404 for missing id" do
    sign_in @user

    assert_api_response :put, 404, path_params: {id: SecureRandom.uuid}, body: {}
  end

  test "PUT /models/:id/use-rsi-image returns 401 when not signed in" do
    model = model_with_rsi_store_image

    assert_api_response :put, 401, path_params: {id: model.id}, body: {}
  end

  test "PUT /models/:id/use-rsi-image returns 403 for admin without access" do
    model = model_with_rsi_store_image
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :put, 403, path_params: {id: model.id}, body: {}
  end
end
