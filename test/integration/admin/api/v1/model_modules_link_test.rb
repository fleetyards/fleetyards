# frozen_string_literal: true

require_relative "../../../../openapi_helper"

class Admin::Api::V1::ModelModulesLinkTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/model-modules/{id}/link" do
    put("Link Model Module to Model") do
      operationId "linkModelModule"
      tags "ModelModules"
      consumes "application/json"
      produces "application/json"

      parameter name: :id, in: :path, required: true, schema: {type: :string, format: :uuid}
      request_body required: true, schema: {
        type: :object,
        properties: {
          modelId: {type: :string, format: :uuid}
        },
        required: [:modelId]
      }

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelModule"
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
    @user = create(:admin_user, resource_access: [:model_modules])
  end

  test "PUT /model-modules/:id/link creates the hardpoint" do
    model = create(:model)
    mod = create(:model_module)
    sign_in @user

    assert_api_response :put, 200, path_params: {id: mod.id}, body: {modelId: model.id} do
      assert_equal 1, ModuleHardpoint.where(model_id: model.id, model_module_id: mod.id).count
    end
  end

  test "PUT /model-modules/:id/link returns 401 when not signed in" do
    model = create(:model)
    mod = create(:model_module)

    assert_api_response :put, 401, path_params: {id: mod.id}, body: {modelId: model.id}
  end

  test "PUT /model-modules/:id/link returns 403 for admin without access" do
    model = create(:model)
    mod = create(:model_module)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :put, 403, path_params: {id: mod.id}, body: {modelId: model.id}
  end
end
