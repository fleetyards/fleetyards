# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "admin/api/v1/model_upgrades", type: :openapi, openapi_schema_name: :"admin/v1/schema" do
  let(:user) { create(:admin_user, resource_access: [:model_upgrades]) }
  let(:model_upgrade) { create(:model_upgrade) }
  let(:id) { model_upgrade.id }

  before do
    sign_in(user) if user.present?
  end

  path "/model-upgrades/{id}" do
    parameter name: "id", in: :path, description: "Model Upgrade id", schema: {type: :string, format: :uuid}

    get("Model Upgrade Detail") do
      operationId "modelUpgrade"
      tags "ModelUpgrades"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelUpgrade"

        run_test!
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
