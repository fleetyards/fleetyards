# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/model_hardpoint_loadouts", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  let(:user) { create(:admin_user, resource_access: [:model_hardpoints]) }
  let(:model_hardpoint_loadout) { create(:model_hardpoint_loadout) }
  let(:id) { model_hardpoint_loadout.id }

  before do
    sign_in(user) if user.present?
  end

  path "/model-hardpoint-loadouts/{id}" do
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, description: "id"

    get("Get Model Hardpoint Loadout") do
      operationId "modelHardpointLoadout"
      tags "ModelHardpointLoadouts"

      consumes "application/json"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelHardpointLoadout"

        run_test!
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:id) { "00000000-0000-0000-0000-000000000000" }

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
