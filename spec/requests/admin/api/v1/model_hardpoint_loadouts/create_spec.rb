# frozen_string_literal: true

require "openapi_helper"

RSpec.describe "admin/api/v1/model_hardpoint_loadouts", type: :openapi, openapi_schema_name: :"admin/v1/schema" do
  let(:user) { create(:admin_user, resource_access: [:model_hardpoints]) }
  let(:model_hardpoint) { create(:model_hardpoint) }
  let(:request_body) do
    {
      name: "Loadout 01",
      modelHardpointId: model_hardpoint.id
    }
  end

  before do
    sign_in(user) if user.present?
  end

  path "/model-hardpoint-loadouts" do
    post("Create Model Hardpoint Loadout") do
      operationId "createModelHardpointLoadout"
      tags "ModelHardpointLoadouts"

      consumes "application/json"
      produces "application/json"

      request_body required: true, content: { "application/json" => { schema: {"$ref": "#/components/schemas/ModelHardpointLoadoutInput"} } }

      response(201, "successful") do
        schema "$ref": "#/components/schemas/ModelHardpointLoadout"

        run_test!
      end

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/ValidationError"

        let(:request_body) { {name: "Missing hardpoint"} }

        run_test!
      end

      include_examples "admin_auth"
    end
  end
end
