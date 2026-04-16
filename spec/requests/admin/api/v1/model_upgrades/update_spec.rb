# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/model_upgrades", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  let(:user) { create(:admin_user, resource_access: [:model_upgrades]) }
  let(:model_upgrade) { create(:model_upgrade) }
  let(:id) { model_upgrade.id }
  let(:input) do
    {
      name: "Updated Upgrade"
    }
  end

  before do
    sign_in(user) if user.present?
  end

  path "/model-upgrades/{id}" do
    parameter name: "id", in: :path, description: "Model Upgrade id", schema: {type: :string, format: :uuid}

    put("Update Model Upgrade") do
      operationId "updateModelUpgrade"
      tags "ModelUpgrades"
      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/ModelUpgradeInput"}, required: true

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelUpgrade"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["name"]).to eq("Updated Upgrade")
        end
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:id) { SecureRandom.uuid }

        run_test!
      end

      include_examples "admin_auth"
    end
  end
end
