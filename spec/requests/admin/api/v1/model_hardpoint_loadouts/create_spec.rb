# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/model_hardpoint_loadouts", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  let(:user) { create(:admin_user, resource_access: [:model_hardpoints]) }
  let(:model_hardpoint) { create(:model_hardpoint) }
  let(:input) do
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

      parameter name: :input, in: :body, schema: {"$ref": "#/components/schemas/ModelHardpointLoadoutInput"}, required: true

      response(201, "successful") do
        schema "$ref": "#/components/schemas/ModelHardpointLoadout"

        run_test!
      end

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/ValidationError"

        let(:input) { {name: "Missing hardpoint"} }

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
