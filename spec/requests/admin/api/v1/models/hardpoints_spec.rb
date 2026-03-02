# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/models", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  let(:user) { create(:admin_user, resource_access: [:models]) }
  let(:model) { create(:model, :with_hardpoints) }
  let(:id) { model.id }

  before do
    sign_in user if user.present?
  end

  path "/models/{id}/hardpoints" do
    parameter name: "id", in: :path, type: :string, description: "Model ID", required: true

    get("Model Hardpoints") do
      operationId "modelHardpoints"
      tags "Models"
      produces "application/json"

      parameter name: "source", in: :query,
        schema: {"$ref": "#/components/schemas/HardpointSourceEnum"}, required: false

      response(200, "successful") do
        schema type: :array,
          items: {
            anyOf: [
              {"$ref": "#/components/schemas/Hardpoint"},
              {"$ref": "#/components/schemas/ModelHardpoint"}
            ]
          }

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.count).to eq(model.model_hardpoints.size)
          expect(data.count).to be > 0
        end
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:id) { "00000000-0000-0000-0000-000000000000" }

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
