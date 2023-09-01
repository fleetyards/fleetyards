# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/public/fleets/vehicles", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :all

  let(:fleet) { fleets :starfleet }

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

          expect(data.count).to be > 0
          expect(data.count).to eq(2)
        end
      end

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetPublicVehicles"

        let(:fleetSlug) { fleet.slug }
        let(:q) do
          {
            "modelNameCont" => "600i"
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.count).to eq(1)
          expect(data.first.dig("model", "name")).to eq("600i")
        end
      end

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetPublicVehicles"

        let(:fleetSlug) { fleet.slug }
        let(:perPage) { 1 }

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.count).to eq(1)
        end
      end

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetPublicVehicles"

        let(:fleetSlug) { fleet.slug }
        let(:grouped) { true }

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.count).to eq(2)
        end
      end

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetPublicVehicles"

        let(:fleet) { fleets :klingon_empire }
        let(:fleetSlug) { fleet.slug }

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.count).to eq(0)
        end
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:fleetSlug) { "unknown-fleet" }

        run_test!
      end
    end
  end
end
