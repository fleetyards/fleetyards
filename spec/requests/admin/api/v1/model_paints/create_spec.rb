# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "admin/api/v1/model_paints", type: :openapi, openapi_schema_name: :"admin/v1/schema" do
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

      include_examples "admin_auth"
    end
  end
end
