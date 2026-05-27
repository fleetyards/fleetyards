# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "admin/api/v1/model_snub_crafts", type: :openapi, openapi_schema_name: :"admin/v1/schema" do
  let(:user) { create(:admin_user, resource_access: [:model_snub_crafts]) }
  let(:model) { create(:model) }
  let(:snub_craft_model) { create(:model) }
  let(:request_body) do
    {
      modelId: model.id,
      snubCraftId: snub_craft_model.id
    }
  end

  before do
    sign_in(user) if user.present?
  end

  path "/model-snub-crafts" do
    post("Create Model Snub Craft") do
      operationId "createModelSnubCraft"
      tags "ModelSnubCrafts"

      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/ModelSnubCraftInput"}

      response(201, "successful") do
        schema "$ref": "#/components/schemas/ModelSnubCraft"

        run_test!
      end

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/ValidationError"

        let(:request_body) { {modelId: "00000000-0000-0000-0000-000000000000"} }

        run_test!
      end

      include_examples "admin_auth"
    end
  end
end
