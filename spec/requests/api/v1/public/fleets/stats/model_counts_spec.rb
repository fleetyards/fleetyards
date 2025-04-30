# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/public/fleets/stats", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:member) { create(:user, vehicle_count: 3) }
  let(:fleet) { create(:fleet, public_fleet: true, members: [member]) }
  let(:fleetSlug) { fleet.slug }

  before do
    Sidekiq::Testing.inline!
  end

  after do
    Sidekiq::Testing.fake!
  end

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

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["modelCounts"]).to eq({
            member.vehicles.first.model.slug => 1,
            member.vehicles.second.model.slug => 1,
            member.vehicles.last.model.slug => 1
          })
        end
      end

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetModelCountsStats"

        let(:q) do
          {
            "modelNameCont" => member.vehicles.first.model.name
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["modelCounts"]).to eq({
            member.vehicles.first.model.slug => 1
          })
        end
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:fleet) { create(:fleet, public_fleet: false) }

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
