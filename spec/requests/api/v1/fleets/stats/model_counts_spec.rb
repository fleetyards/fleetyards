# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleets/stats", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :all

  let(:fleet) { fleets :starfleet }

  let(:user) { nil }

  before do
    sign_in(user) if user.present?
  end

  path "/fleets/{fleetSlug}/stats/model-counts" do
    parameter name: "fleetSlug", in: :path, type: :string, description: "Fleet slug"

    get("Fleet Stats Model Counts") do
      operationId "fleetModelCounts"
      tags "FleetStats"
      produces "application/json"

      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/FleetVehicleQuery"
        },
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetModelCountsStats"

        let(:fleetSlug) { fleet.slug }
        let(:user) { users :data }

        after do |example|
          example.metadata[:response][:content] = {
            "application/json" => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["modelCounts"]).to eq({
            "600i-explorer" => 1,
            "constellation-andromeda" => 1
          })
        end
      end

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetModelCountsStats"

        let(:fleetSlug) { fleet.slug }
        let(:user) { users :data }
        let(:q) do
          {
            "modelNameCont" => "600i Explorer"
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["modelCounts"]).to eq({
            "600i-explorer" => 1
          })
        end
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:fleetSlug) { "unknown-fleet" }
        let(:user) { users :data }

        run_test!
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:fleetSlug) { fleet.slug }

        run_test!
      end
    end
  end
end
