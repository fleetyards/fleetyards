# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/model_upgrades", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  let(:user) { create(:admin_user, resource_access: [:model_upgrades]) }
  let(:model_upgrade) { create(:model_upgrade) }
  let(:id) { model_upgrade.id }

  before do
    sign_in(user) if user.present?
  end

  path "/model-upgrades/{id}" do
    parameter name: "id", in: :path, description: "Model Upgrade id", schema: {type: :string, format: :uuid}

    delete("Destroy Model Upgrade") do
      operationId "destroyModelUpgrade"
      tags "ModelUpgrades"

      response(204, "successful") do
        run_test!
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:id) { SecureRandom.uuid }

        run_test!
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
