# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "admin/api/v1/model_snub_crafts", type: :openapi, openapi_schema_name: :"admin/v1/schema" do
  let(:user) { create(:admin_user, resource_access: [:model_snub_crafts]) }
  let(:model_snub_craft) { create(:model_snub_craft) }
  let(:id) { model_snub_craft.id }
  let(:new_snub_craft_model) { create(:model) }
  let(:request_body) do
    {
      snubCraftId: new_snub_craft_model.id
    }
  end

  before do
    sign_in(user) if user.present?
  end

  path "/model-snub-crafts/{id}" do
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, description: "id"

    put("Update Model Snub Craft") do
      operationId "updateModelSnubCraft"
      tags "ModelSnubCrafts"

      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/ModelSnubCraftInput"}

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelSnubCraft"

        run_test!
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:id) { "00000000-0000-0000-0000-000000000000" }

        run_test!
      end

      include_examples "admin_auth"
    end
  end
end
