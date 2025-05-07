# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/fleets/stats", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:member) { create(:user) }
  let(:vehicle) { create(:vehicle, user: member) }
  let(:vehicle_2) { create(:vehicle, user: member) }
  let(:vehicle_3) { create(:vehicle, model: vehicle.model, user: member) }
  let(:fleet) { create(:fleet, members: [member]) }
  let(:user) { member }
  let(:fleetSlug) { fleet.slug }

  before do
    Sidekiq::Testing.inline!

    vehicle
    vehicle_2
    vehicle_3

    sign_in(user) if user.present?
  end

  after do
    Sidekiq::Testing.fake!
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

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["modelCounts"]).to eq({
            vehicle.model.slug => 2,
            vehicle_2.model.slug => 1
          })
        end
      end

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetModelCountsStats"

        let(:q) do
          {
            "modelNameCont" => vehicle.model.name
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data["modelCounts"]).to eq({
            vehicle.model.slug => 2
          })
        end
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:fleetSlug) { "unknown-fleet" }

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
