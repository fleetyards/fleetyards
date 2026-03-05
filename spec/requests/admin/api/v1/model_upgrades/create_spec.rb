# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/model_upgrades", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  let(:user) { create(:admin_user, resource_access: [:model_upgrades]) }
  let(:model) { create(:model) }
  let(:input) do
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

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/ModelUpgradeInput"}, required: true

      response(201, "successful") do
        schema "$ref": "#/components/schemas/ModelUpgrade"

        run_test! do
          created_upgrade = ModelUpgrade.last

          expect(created_upgrade.upgrade_kits.count).to eq(1)
          expect(created_upgrade.upgrade_kits.first.model_id).to eq(model.id)
        end
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { create(:admin_user, resource_access: []) }

        run_test!
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:user) { nil }

        run_test!
      end
    end
  end
end
