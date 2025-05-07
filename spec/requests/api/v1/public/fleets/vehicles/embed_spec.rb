# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/public/fleets/vehicles", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:member) { create(:user, vehicle_count: 3) }
  let(:fleet) { create(:fleet, public_fleet: true, members: [member]) }
  let(:fleetSlug) { fleet.slug }

  before do
    Sidekiq::Testing.inline!
  end

  after do
    Sidekiq::Testing.fake!
  end

  path "/public/fleets/{fleetSlug}/vehicles/embed" do
    parameter name: "fleetSlug", in: :path, type: :string, description: "Fleet slug"

    get("Public Fleet Vehicles Embed for the Fleetyards Widget") do
      operationId "publicFleetVehiclesEmbed"
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
        schema type: :array,
          items: {"$ref": "#/components/schemas/VehiclePublic"}

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.count).to be > 0
          expect(data.count).to eq(3)
        end
      end

      response(200, "successful") do
        schema type: :array,
          items: {"$ref": "#/components/schemas/VehiclePublic"}

        let(:q) do
          {
            "modelNameCont" => member.vehicles.first.model.name
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.count).to eq(1)
          expect(data.first.dig("model", "name")).to eq(member.vehicles.first.model.name)
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
