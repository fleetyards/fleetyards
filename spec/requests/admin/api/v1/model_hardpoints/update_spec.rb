# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "admin/api/v1/model_hardpoints", type: :openapi, openapi_schema_name: :"admin/v1/schema" do
  let(:user) { create(:admin_user, resource_access: [:model_hardpoints]) }
  let(:model_hardpoint) { create(:model_hardpoint) }
  let(:id) { model_hardpoint.id }
  let(:request_body) do
    {
      name: "Updated Hardpoint"
    }
  end

  before do
    sign_in(user) if user.present?
  end

  path "/model-hardpoints/{id}" do
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, description: "id"

    put("Update Model Hardpoint") do
      operationId "updateModelHardpoint"
      tags "ModelHardpoints"

      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/ModelHardpointInput"}

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelHardpoint"

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
