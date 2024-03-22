# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/public/fleets/stats", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :all

  let(:fleet) { fleets :starfleet }

  path "/public/fleets/{fleetSlug}/stats/model-counts" do
    parameter name: "fleetSlug", in: :path, type: :string, description: "Fleet slug"

    get("Public Fleet Stats Model Counts") do
      operationId "publicFleetStatsModelCounts"
      tags "Fleets"
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
            "andromeda" => 1,
            "600i" => 1,
            "ptv" => 1
          })
        end
      end

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetModelCountsStats"

        let(:fleetSlug) { fleet.slug }
        let(:q) do
          {
            "modelNameCont" => "600i"
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["modelCounts"]).to eq({
            "600i" => 1
          })
        end
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:fleet) { fleets :klingon_empire }
        let(:fleetSlug) { fleet.slug }

        run_test!
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:fleetSlug) { "unknown-fleet" }

        run_test!
      end
    end
  end
end
