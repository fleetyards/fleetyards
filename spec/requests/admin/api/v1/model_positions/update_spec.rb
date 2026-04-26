# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "admin/api/v1/model_positions", type: :openapi, openapi_schema_name: :"admin/v1/schema" do
  let(:user) { create(:admin_user, resource_access: [:model_positions]) }
  let(:model_position) { create(:model_position) }
  let(:id) { model_position.id }
  let(:request_body) do
    {
      name: "Updated Position"
    }
  end

  before do
    sign_in(user) if user.present?
  end

  path "/model-positions/{id}" do
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, description: "id"

    put("Update Model Position") do
      operationId "updateModelPosition"
      tags "ModelPositions"

      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/ModelPositionInput"}

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelPosition"

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
