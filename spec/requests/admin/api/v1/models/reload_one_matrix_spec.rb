# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/models", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  let(:user) { create(:admin_user, resource_access: [:models]) }
  let(:model) { create(:model) }
  let(:id) { model.id }

  before do
    sign_in(user) if user.present?
  end

  path "/models/{id}/reload-one-matrix" do
    parameter name: "id", in: :path, description: "Model id", schema: {type: :string, format: :uuid}

    put("Reload Single Model Matrix") do
      operationId "reloadOneModelMatrix"
      tags "Models"
      produces "application/json"

      response(200, "successful") do
        schema type: :object, properties: {message: {type: :string}}, required: [:message]

        before do
          allow(Loaders::ModelJob).to receive(:perform_async)
        end

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
