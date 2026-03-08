# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/model_upgrades", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  let(:user) { create(:admin_user, resource_access: [:model_upgrades]) }
  let(:model) { create(:model) }
  let(:model_upgrade) { create(:model_upgrade) }
  let(:id) { model_upgrade.id }

  before do
    sign_in(user) if user.present?
  end

  path "/model-upgrades/{id}/link" do
    put("Link Model Upgrade to Model") do
      operationId "linkModelUpgrade"
      tags "ModelUpgrades"

      consumes "application/json"
      produces "application/json"

      parameter name: :id, in: :path, required: true, schema: {type: :string, format: :uuid}
      parameter name: :input, in: :body, schema: {
        type: :object,
        properties: {
          modelId: {type: :string, format: :uuid}
        },
        required: [:modelId]
      }, required: true

      let(:input) { {modelId: model.id} }

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelUpgrade"

        run_test! do
          expect(UpgradeKit.where(model_id: model.id, model_upgrade_id: model_upgrade.id).count).to eq(1)
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

  path "/model-upgrades/{id}/unlink" do
    put("Unlink Model Upgrade from Model") do
      operationId "unlinkModelUpgrade"
      tags "ModelUpgrades"

      consumes "application/json"
      produces "application/json"

      parameter name: :id, in: :path, required: true, schema: {type: :string, format: :uuid}
      parameter name: :input, in: :body, schema: {
        type: :object,
        properties: {
          modelId: {type: :string, format: :uuid}
        },
        required: [:modelId]
      }, required: true

      let(:input) { {modelId: model.id} }

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelUpgrade"

        before do
          UpgradeKit.create!(model: model, model_upgrade: model_upgrade)
        end

        run_test! do
          expect(UpgradeKit.where(model_id: model.id, model_upgrade_id: model_upgrade.id).count).to eq(0)
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
