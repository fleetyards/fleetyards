# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/model_paints", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  let(:user) { create(:admin_user, resource_access: [:model_paints]) }
  let(:model) { create(:model) }
  let(:input) do
    {
      name: "Midnight Blue",
      modelId: model.id
    }
  end

  before do
    sign_in(user) if user.present?
  end

  path "/model-paints" do
    post("Create Model Paint") do
      operationId "createModelPaint"
      tags "ModelPaints"
      consumes "application/json"
      produces "application/json"

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/ModelPaintInput"}, required: true

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelPaint"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["name"]).to eq("Midnight Blue")
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
