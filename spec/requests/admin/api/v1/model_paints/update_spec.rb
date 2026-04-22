# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "admin/api/v1/model_paints", type: :openapi, openapi_schema_name: :"admin/v1/schema" do
  let(:user) { create(:admin_user, resource_access: [:model_paints]) }
  let(:model_paint) { create(:model_paint) }
  let(:id) { model_paint.id }
  let(:request_body) do
    {
      name: "Updated Paint"
    }
  end

  before do
    sign_in(user) if user.present?
  end

  path "/model-paints/{id}" do
    parameter name: "id", in: :path, description: "Model Paint id", schema: {type: :string, format: :uuid}

    put("Update Model Paint") do
      operationId "updateModelPaint"
      tags "ModelPaints"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/ModelPaintInput"}

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelPaint"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["name"]).to eq("Updated Paint")
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
