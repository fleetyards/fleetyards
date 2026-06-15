# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::ModelUpgradesUnlinkTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/model-upgrades/{id}/unlink" do
    put("Unlink Model Upgrade from Model") do
      operationId "unlinkModelUpgrade"
      tags "ModelUpgrades"
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
        schema "$ref": "#/components/schemas/ModelUpgrade"
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
    @user = create(:admin_user, resource_access: [:model_upgrades])
  end

  test "PUT /model-upgrades/:id/unlink removes the upgrade kit" do
    model = create(:model)
    upgrade = create(:model_upgrade)
    UpgradeKit.create!(model: model, model_upgrade: upgrade)
    sign_in @user

    assert_api_response :put, 200, path_params: {id: upgrade.id}, body: {modelId: model.id} do
      assert_equal 0, UpgradeKit.where(model_id: model.id, model_upgrade_id: upgrade.id).count
    end
  end

  test "PUT /model-upgrades/:id/unlink returns 401 when not signed in" do
    model = create(:model)
    upgrade = create(:model_upgrade)

    assert_api_response :put, 401, path_params: {id: upgrade.id}, body: {modelId: model.id}
  end

  test "PUT /model-upgrades/:id/unlink returns 403 for admin without access" do
    model = create(:model)
    upgrade = create(:model_upgrade)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :put, 403, path_params: {id: upgrade.id}, body: {modelId: model.id}
  end
end
