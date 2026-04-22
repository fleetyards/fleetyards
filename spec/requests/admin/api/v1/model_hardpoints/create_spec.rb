# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "admin/api/v1/model_hardpoints", type: :openapi, openapi_schema_name: :"admin/v1/schema" do
  let(:user) { create(:admin_user, resource_access: [:model_hardpoints]) }
  let(:model) { create(:model) }
  let(:request_body) do
    {
      name: "Hardpoint 01",
      source: "ship_matrix",
      key: "hardpoint_01",
      hardpointType: "weapons",
      group: "weapon",
      modelId: model.id
    }
  end

  before do
    sign_in(user) if user.present?
  end

  path "/model-hardpoints" do
    post("Create Model Hardpoint") do
      operationId "createModelHardpoint"
      tags "ModelHardpoints"

      consumes "application/json"
      produces "application/json"

      request_body required: true, content: { "application/json" => { schema: {"$ref": "#/components/schemas/ModelHardpointInput"} } }

      response(201, "successful") do
        schema "$ref": "#/components/schemas/ModelHardpoint"

        run_test!
      end

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/ValidationError"

        let(:request_body) { {name: "Missing required fields"} }

        run_test!
      end

      include_examples "admin_auth"
    end
  end
end
