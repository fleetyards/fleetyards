# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/public/fleets/vehicles", type: :request, swagger_doc: "v1/schema.yaml" do
  fixtures :all

  let(:fleet) { fleets :starfleet }

  path "/public/fleets/{slug}/vehicles/embed" do
    parameter name: "slug", in: :path, type: :string, description: "slug"

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
          items: {"$ref": "#/components/schemas/VehiclePublicMinimal"}

        let(:slug) { fleet.slug }

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
          expect(data.count).to eq(3)
        end
      end

      response(200, "successful") do
        schema type: :array,
          items: {"$ref": "#/components/schemas/VehiclePublicMinimal"}

        let(:slug) { fleet.slug }
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
        schema type: :array,
          items: {"$ref": "#/components/schemas/VehiclePublicMinimal"}

        let(:fleet) { fleets :klingon_empire }
        let(:slug) { fleet.slug }

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data.count).to eq(0)
        end
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"

        let(:slug) { "unknown-fleet" }

        run_test!
      end
    end
  end
end
