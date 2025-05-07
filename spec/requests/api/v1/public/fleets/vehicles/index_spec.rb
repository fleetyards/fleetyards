# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/public/fleets/vehicles", type: :request, swagger_doc: "v1/schema.yaml" do
  let(:member) { create(:user, vehicle_count: 2) }
  let(:fleet) { create(:fleet, public_fleet: true, members: [member]) }
  let(:fleetSlug) { fleet.slug }

  before do
    Sidekiq::Testing.inline!
  end

  after do
    Sidekiq::Testing.fake!
  end

  path "/public/fleets/{fleetSlug}/vehicles" do
    parameter name: "fleetSlug", in: :path, type: :string, description: "Fleet slug"

    get("Public Fleet Vehicles List") do
      operationId "publicFleetVehicles"
      tags "Fleets"
      produces "application/json"

      parameter name: "page", in: :query, schema: {type: :string, default: "1"}, required: false
      parameter name: "perPage", in: :query, schema: {type: :string, default: FleetVehicle.default_per_page}, required: false
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/FleetVehicleQuery"
        },
        style: :deepObject,
        explode: true,
        required: false
      parameter name: "grouped", in: :query, type: :boolean, required: false
      parameter name: "cacheId", in: :query, type: :string, required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetPublicVehicles"

        run_test! do |response|
          data = JSON.parse(response.body)
          items = data["items"]

          expect(items.count).to be > 0
          expect(items.count).to eq(2)
        end
      end

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetPublicVehicles"

        let(:fleetSlug) { fleet.slug }
        let(:q) do
          {
            "modelNameCont" => member.vehicles.first.model.name
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          items = data["items"]

          expect(items.count).to eq(1)
          expect(items.first.dig("model", "name")).to eq(member.vehicles.first.model.name)
        end
      end

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetPublicVehicles"

        let(:perPage) { 1 }

        run_test! do |response|
          data = JSON.parse(response.body)
          items = data["items"]

          expect(items.count).to eq(1)
        end
      end

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetPublicVehicles"

        let(:grouped) { true }

        run_test! do |response|
          data = JSON.parse(response.body)
          items = data["items"]

          expect(items.count).to eq(2)
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
