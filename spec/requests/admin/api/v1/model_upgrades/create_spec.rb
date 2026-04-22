# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "admin/api/v1/model_upgrades", type: :openapi, openapi_schema_name: :"admin/v1/schema" do
  let(:user) { create(:admin_user, resource_access: [:model_upgrades]) }
  let(:model) { create(:model) }
  let(:request_body) do
    {
      name: "Warbond Upgrade",
      modelId: model.id
    }
  end

  before do
    sign_in(user) if user.present?
  end

  path "/model-upgrades" do
    post("Create Model Upgrade") do
      operationId "createModelUpgrade"
      tags "ModelUpgrades"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/ModelUpgradeInput"}

      response(201, "successful") do
        schema "$ref": "#/components/schemas/ModelUpgrade"

        run_test! do
          created_upgrade = ModelUpgrade.last

          expect(created_upgrade.upgrade_kits.count).to eq(1)
          expect(created_upgrade.upgrade_kits.first.model_id).to eq(model.id)
        end
      end

      include_examples "admin_auth"
    end
  end
end
