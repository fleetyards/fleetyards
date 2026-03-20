# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "admin/api/v1/model_hardpoint_loadouts", type: :request, swagger_doc: "admin/v1/schema.yaml" do
  let(:user) { create(:admin_user, resource_access: [:model_hardpoints]) }
  let(:model_hardpoint_loadouts) { create_list(:model_hardpoint_loadout, 3) }

  before do
    sign_in user if user.present?

    model_hardpoint_loadouts
  end

  path "/model-hardpoint-loadouts" do
    get("Model Hardpoint Loadouts list") do
      operationId "listModelHardpointLoadouts"
      tags "ModelHardpointLoadouts"

      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: 30}, required: false
      parameter name: "q", in: :query,
        schema: {
          "$ref": "#/components/schemas/ModelHardpointLoadoutQuery"
        },
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ModelHardpointLoadouts"

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["items"].count).to eq(3)
        end
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
